if ship:status = "prelaunch" {
  // this script is supposed to be run via action group
  shutdown.
}
core:doevent("open terminal").
for x in range(terminal:height) {
  print " ".  // push the cursor to the bottom
}

local target_chute is false.
for chute in ship:modulesnamed("ModuleParachute") {
  set chute:part:tag to "target-chute".
  set target_chute to "target-chute".
  break.
}

// ladderClimbSpeed = 0.60
local bottom_ladder is 0.
local bottom_ladder_distance is 0.
for ladder in ship:modulesnamed("RetractableLadder") {
  local lock ladder_distance to (ship:rootpart:position - ladder:part:position):mag.
  if ladder_distance > bottom_ladder_distance {
    set bottom_ladder_distance to ladder_distance.
    set bottom_ladder to ladder.
  }
}
set bottom_ladder:part:tag to "bottom_ladder".
unlock ladder_distance.

// print "Would you like to plant a flag (y/N)".
// local need_flag is terminal:input:getchar = "y".
local crew_list is ship:crew:copy.
local need_flag is false.
local flags_planted_file is "0:/data/flags-" + body:name + ".json".
local flags_planted_by is uniqueset().
local crew_by_trait is lex().
if exists(flags_planted_file) {
  // might need uniqueset(readjson())
  set flags_planted_by to readjson(flags_planted_file).
}
for crew in ship:crew {
  set crew_by_trait[crew:trait] to crew.
  if not flags_planted_by:contains(crew:name) {
    set need_flag to true.
  }
}

local flag_planter is false.
for trait in list("pilot", "scientist", "engineer") {
  if crew_by_trait:haskey(trait) {
    set flag_planter to crew_by_trait[trait].
    break.
  }
}
print "Flag planter: " + flag_planter.
local flag_part is flag_planter:part:tag.

if ship:status = "landed" and need_flag {
  print "Sending " + flag_planter:name + " to plant a flag".
  addons:eva:goeva(flag_planter).
  wait until kuniverse:activevessel <> ship.
  local connection is vessel(flag_planter:name):connection.
  connection:sendmessage(list("home", flag_part)).
  connection:sendmessage(list("tosurface")).
  connection:sendmessage(list("turn", 120 + 120 * random())).
  connection:sendmessage(list("forward", 8 + 7 * random())).
  connection:sendmessage(list("flag")).
  connection:sendmessage(list("return")).

  // use the copy here, because they will be on eva
  for crew in crew_list {
    flags_planted_by:add(crew:name).
  }
  // writejson(flags_planted_by, flags_planted_file).
}

if target_chute:istype("string") and crew_by_trait:haskey("engineer") {
  local engineer is crew_by_trait["engineer"].
  local home_part is engineer:part:tag.
  if need_flag and flag_planter:name = engineer:name {
    wait until ship:crew:len = crew_list:len.
  }
  else {
    wait 2.  // for flag planter to get out of the way of the hatch
  }
  print "Sending " + engineer:name + " to repack the chutes".
  kuniverse:forceactive(ship).
  wait until kuniverse:activevessel = ship.
  addons:eva:goeva(engineer).
  wait until kuniverse:activevessel <> ship.
  local connection is vessel(engineer:name):connection.
  connection:sendmessage(list("evato", target_chute, "up")).
  connection:sendmessage(list("repack")).
  connection:sendmessage(list("evato", home_part, "down")).
  connection:sendmessage(list("board")).
}

