wait until ship:unpacked.
if ship:status = "prelaunch" and kuniverse:origineditor = "vab" {
  shutdown.
}
core:doevent("open terminal").

if ship:status = "prelaunch" {
  if hastarget {
    dock().
  }
  else {
    // for testing, wait until undocked
    if ship:parts:length < 30 {
      mine().
    }
    else {
      brakes on.
    }
  }
}
else {
  if ship:status = "landed" {
    mine().
  }
  else {
    dock().
  }
}
shutdown.

function mine {
  brakes on.
  deploydrills on.
  panels on.
  radiators on.
  print "Waiting for drills to deploy...".
  // wait for panels to be deployed
  wait 5.
  print "Starting drills...".
  drills on.

  local ore is 0.
  for res in ship:resources {
    if res:name = "ore" {
      set ore to res.
      break.
    }
  }

  // determine when the ore tank will be full and set alarm
  if (ore:amount / ore:capacity) < 0.95 {
    // future enhancement - wait until thermal efficiency is near 100%
    local initial is ore:amount.
    local duration is 10.
    wait until ore:amount <> initial.
    wait duration.
    local mine_rate is (ore:amount - initial) / duration.
    local remaining is (ore:capacity - ore:amount) / mine_rate.
    print "ETA: " + remaining + " seconds".

    if addons:available("kac") {
      local alarm is addalarm("raw", time:seconds + remaining, ship:name + " ore full", "Time to head back to ISRU station for processing").
      set alarm:action to "KillWarp".
    }
  }

  wait until ore:amount >= ore:capacity.
  print "Ore tanks are full, shutting down".
  drills off.
  deploydrills off.
  radiators off.
}

function dock {
  if not hastarget {
    return.
  }

  local miner_id is core:element:uid.
  local port is core:element:dockingports[0].
  local inbound is list("station", "miner").
  local outbound is list("miner", "station").
  local directions is lexicon(
    "ore",            outbound,
    "liquidFuel",     inbound,
    "oxidizer",       inbound,
    "monopropellant", inbound
  ).

  // create basic structure: lex(section => lex(res:name => parts))
  // where section is either "miner" or "station"
  local plex is lexicon().
  for section in inbound {
    set plex[section] to lexicon().
    for resource in directions:keys {
      set plex[section][resource] to list().
    }
  }

  print "Waiting for docking...".
  wait until port:state:startswith("docked").

  // fill in all of the actual parts - since the structure has already been
  // initialized, the parts can just be added to the lists
  for element in ship:elements {
    for resource in element:resources {
      local section is choose "miner" if element:uid = miner_id else "station".
      if plex[section]:haskey(resource:name) {
        for part in resource:parts {
          plex[section][resource:name]:add(part).
        }
      }
    }
  }

  print "Starting transfers...".
  local tx is lexicon().
  for res in directions:keys {
    local source is directions[res][0].
    local dest is directions[res][1].
    set tx[res] to make_transfer(res, plex[source][res], plex[dest][res]).
  }

  for res in tx:keys {
    local xfr is tx[res].
    print "Waiting for " + xfr + " - " + xfr:status.
    wait until not xfr:active.
    print res + " transfer " + xfr:status + " (" + xfr:message + ")".
  }
  print "All transfers complete".
}

function make_transfer {
  parameter res_name, source, dest.
  // if either source or dest is empty, the transfer fails gracefully
  local xfr is transferall(res_name, source, dest).
  xfr:active on.
  return xfr.
}
