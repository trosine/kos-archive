wait 2.
sas off.
brakes off.
list targets.

// get off the runway and pull the gear up
lock wheelsteering to 0.
lock wheelthrottle to 1.
local old_alt is altitude.
wait until altitude < old_alt - 4.
unlock wheelthrottle.
unlock wheelsteering.
brakes on.
wait until groundspeed < 0.1.
gear off.

// make it easy for the kerbal to find the part they came from
for member in ship:crew set member:part:tag to member:name.

// make sure we settle back down
wait 5.

// collect some crew reports for kerbals to try to take
local cmods is ship:modulesnamed("ModuleScienceExperiment").
for cmod in cmods {
  cmod:deploy.
  wait until cmod:hasdata.
  print cmod:part:tag.
  print cmod:data[0]:title.
}

for member in ship:crew {
  print "sending " + member:name.
  addons:eva:goeva(member).
  wait 7.
  vessel(member:name):connection:sendmessage("go").
}

list targets.
