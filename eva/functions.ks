set ae to addons:eva.
set f to lexicon(
  "evato", {
    local what is msg:sender:partstagged(msg:content[1])[0].
    local dir is "forward".
    if msg:content:length > 2 {
      set dir to msg:content[2].
    }
    evato(what, dir).
  },
  "home", {
    global home is msg:sender:partstagged(msg:content[1])[0].
    global home_alt is ship:altitude.
  },
  "take", {
    for e in shipexp() {
      ae:doevent(e:part, "Collect Data").   // goo, materials bay
      ae:doevent(e:part, "Take Data").      // temp, pressure, accel, grav, crew
      ae:doevent(e:part, "Download Data").  // atmospheric
    }
  },
  "reset", {
    for e in shipexp() ae:doevent(e:part, "reset").
  },
  "report", {
    local mx is ship:modulesnamed("ModuleScienceExperiment").
    for e in mx {
      if e:allevents:length {
        e:deploy.
        wait until e:hasdata.
      }
    }
    ae:doevent(home, "Store Experiments").
    wait until not mx[0]:hasdata.
    msg:sender:connection:sendmessage("report complete").
  },
  "flag", {
    ae:plantflag(body:name + ": " + addons:scansat:currentbiome, "").
    wait 4.
  },
  "repack", {
    for p in msg:sender:modulesnamed("ModuleParachute") {
      ae:doevent(p:part, "Repack").
    }
  },
  "turn", {
    local degrees is msg:content[1].
    hudtext("Turning " + degrees + " degrees", 5, 2, 20, yellow, false).
    if degrees > 180 {
      ae:turn_left(360-degrees).
    }
    else {
      ae:turn_right(degrees).
    }
    wait 3.
  },
  "grab ladder", {ae:ladder_grab.},
  "release ladder", {
    ae:ladder_release.
    wait 3.
  },
  "tosurface", {
    ae:move("down").
    wait until (ship:altitude - geoposition:terrainheight) < 0.4.
    ae:ladder_release.
    wait 3.
    global ladder_coordinate is geoposition.
  },
  "forward", {
    local distance is msg:content[1].
    ae:move("forward").
    wait distance.
    ae:move("stop").
  },
  "return", {
    evato(ladder_coordinate).
    ae:ladder_grab.
    ae:move("up").
    wait until ship:altitude > home_alt.
    ae:board.
  },
  "board", {ae:board.}
).

// primarily intended for up, down, forward
// get as close as possible to the part
function evato {
  parameter what.  // anything that has a :position suffix
  parameter dir is "forward".
  local lock cur_mag to (what:position - ship:position):mag.

  if dir = "forward" {
    ae:turn_to(what:position).
    // until heading stops changing?
    wait 3.
  }

  local last_mag is cur_mag.
  until cur_mag - last_mag > 0 {
    if dir = "forward" {
      ae:turn_to(what:position).
      wait 0.
    }
    ae:move(dir).
    set last_mag to cur_mag.
    wait 0.1.
  }
  ae:move("stop").
}

function shipexp {
  return msg:sender:modulesnamed("ModuleScienceExperiment").
}
