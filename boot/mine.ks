wait until ship:unpacked.
if ship:status = "prelaunch" and kuniverse:origineditor = "vab" {
  shutdown.
}
// core:doevent("open terminal").

if ship:status = "prelaunch" {
  // for testing, wait until undocked
  if ship:parts:length < 30 {
    mine().
  }
  else {
    brakes on.
  }
}
else {
  if ship:status = "landed" {
    mine().
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
