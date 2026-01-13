wait until ship:unpacked.
// if ship:status = "prelaunch" {
//   shutdown.
// }
core:doevent("open terminal").

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
// if ship:status = "landed" {
//   mine().
// }
// else {
//   dock().
// }
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
  local fuels is list("liquidFuel", "oxidizer", "monopropellant").
  local ores is list("ore").

  print "Waiting for docking...".
  wait until port:state:startswith("docked").

  // create list of parts where element:uid <> core:element:uid
  local miner_parts is lexicon().
  local res_parts is lexicon().
  for element in ship:elements {
    for resource in element:resources {
      local res_name is resource:name.
      if element:uid = miner_id {
        set miner_parts[res_name] to resource:parts.
      }
      else {
        if not res_parts:haskey(res_name) {
          set res_parts[res_name] to list().
        }
        for part in resource:parts {
          res_parts[res_name]:add(part).
        }
      }
    }
  }

  print "Transferring...".
  local tx is lexicon().
  for res in ores {
    if res_parts:haskey(res) {
      set tx[res] to make_transfer(res, miner_parts[res], res_parts[res]).
    }
  }
  for res in fuels {
    if res_parts:haskey(res) {
      set tx[res] to make_transfer(res, res_parts[res], miner_parts[res]).
    }
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
  local xfr is transferall(res_name, source, dest).
  print xfr.
  xfr:active on.
  return xfr.
}
