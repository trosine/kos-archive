if ship:status = "prelaunch" {
  shutdown.
}
core:doevent("open terminal").
for x in range(terminal:height) print " ".
// Collect all available science on this vessel
// assumes that there's only going to be one of each experiment type
local experiments is ship:modulesnamed("ModuleScienceExperiment").
local invalid_experiment is lex(
  "sensorGravimeter", uniqueset("FLYING"),
  "sensorAccelerometer", uniqueset("SPLASHED", "FLYING", "SUB_ORBITAL", "ORBITING"),
  "sensorAtmosphere", uniqueset("SPLASHED", "SUB_ORBITAL", "ORBITING")
).

local partnum is 0.
// crewed containers always have a "Crew Report" experiment, and cannot "Collect All"
local containers is list().
for cont in ship:modulesnamed("ModuleScienceContainer") {
  if cont:part:hasmodule("ModuleScienceExperiment") {
    // set tags on crew parts, so kerbals get get back to them
    set cont:part:tag to "crew part " + partnum.
    set partnum to partnum + 1.
  }
  else {
    containers:add(cont).
  }
}

local scientist is false.
local sci_connect is false.
for crew in ship:crew {
  if crew:trait = "scientist" {
    set scientist to crew.
    break.
  }
}

if scientist:istype("CrewMember") {
  local scitag is scientist:part:tag.
  print "Sending " + scientist:name + " (hometag=" + scitag + ")".
  addons:eva:goeva(scientist).
  // KSP auto-switches to the kerbal
  wait until kuniverse:activevessel <> ship.
  // tell the kerbal which part they came from
  set sci_connect to vessel(scientist:name):connection.
  sci_connect:sendmessage(list("home", scitag)).
}
else {
  print "WARNING: No scientist on board - goo canisters/materials bays cannot be reset".
  // also, no EVA/surface samples taken
}

for container in containers {
  print "Gathering data for " + container:part:title.
  collect_data(sci_connect, container).
}

// one more for the crew cabin
// if this was collected before the container loop the crew report wouldn't get taken
if scientist:istype("CrewMember") {
  print "Collecting for crew part".
  collect_data(sci_connect).
  sci_connect:sendmessage(list("board")).
}

print "Data collection compelete".


function collect_data {
  parameter connection, container is false.
  local has_connection is connection:istype("Connection").
  local has_container is container:istype("PartModule").

  run_experiments().
  if has_connection {
    if not has_container {
      // collect data from all experiments (including the crew report)
      connection:sendmessage(list("take")).
    }
    print "  Requesting reports".
    // The kerbal would be on a ladder, preventing normal switching
    kuniverse:forceactive(vessel(scientist:name)).
    wait until kuniverse:activevessel <> ship.
    connection:sendmessage(list("report")).  // and store reports in source part
    wait until ship:messages:length.
    print "    " + ship:messages:pop:content.
  }

  if has_container {
    // The kerbal would be on a ladder, preventing normal switching
    kuniverse:forceactive(ship).
    wait until kuniverse:activevessel = ship.
    for container in containers {
    print "  Collecting into " + container:part:title.
    container:doaction("Collect All", true).
    }
  }

  if has_connection {
    print "  Waiting for data collection".
    for experiment in experiments wait until not experiment:hasdata.
    print "  Telling to reset".
    kuniverse:forceactive(vessel(scientist:name)).
    wait until kuniverse:activevessel <> ship.
    connection:sendmessage(list("reset")).
    print "  Waiting for reset completion".
    for experiment in experiments wait until not experiment:inoperable.
  }
}


function run_experiments {
  // run experiments concurrently
  // might need to check for inoperable/hasdata
  for experiment in experiments experiment:deploy.
  print "  Waiting for all data".
  for experiment in experiments {
    if invalid_experiment:haskey(experiment:part:name) {
      if not invalid_experiment[experiment:part:name]:contains(ship:status) {
        // print "    Waiting on " + ship:status + " valid " + experiment:part:name.
        wait until experiment:hasdata.
      }
    }
    else {
      // print "    Waiting on always valid " + experiment:part:name.
      wait until experiment:hasdata.
    }
  }
}
