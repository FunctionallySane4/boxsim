#TODO: Consider making freeze frames
# TODO combos!!
# TODO prototype version of decisiontry by hardcoding probabilities
# TODO add boundaries/wall/ or camera movement mayhaps
#
import nico
import nico/vec
import std/random, std/sequtils, std/math
import fighter

const orgName = "fsane"
const appName = "boxsim"


var elapsed: float32 = 0.0
var reset_on :float32 = 1.0
var match_end : bool = false # use a general checker for this

randomize()

proc random_action() : Moves =
  let moves = toSeq Moves
  let rng = rand 5 # get len of moves later instead
  return moves[rng]

var fighter1, fighter2: Fighter;
let x_corner = (blue: 10.0, red: 90.0)

proc gameInit() =
  loadFont(0, "font.png")
  loadSpritesheet(0, "blue.png", 8, 8)
  loadSpritesheet(1, "red.png", 8, 8)
  loadSfx(0, "hitHurt.ogg")
  loadSfx(1, "ko.ogg")
  loadMusic(2,"music2.ogg")
  music(1, 2)


  fighter1 = Fighter(
    pos: vec2f(x_corner.blue, 64),
    corner: BlueCorner,
    index: 0,
    frame: 0,
    attack_range: 4,
    facing: Right,
    stats: Stats(
      max_health: 100.0,
      health: 100.0,
      strength: 8.0,
      agility: 1.0,
      weight: 2.0,
      speed: 1.0
    )
  )

  fighter2 = Fighter(
    pos: vec2f(x_corner.red, 64),
    corner:RedCorner,
    index: 1,
    frame: 0,
    attack_range: 4,
    facing: Left,
    stats: Stats(
      max_health: 100.0,
      health: 100.0,
      strength: 8,
      agility: 1.5,
      weight: 2.0,
      speed: 1.0
    )
  )

proc health_bar(fighter: Fighter, color : int) =
  var pc : float32 = fighter.stats.health / fighter.stats.max_health
  var pos = vec2f(fighter.pos.x, fighter.pos.y + 10)
  var len = (9.0 * pc) - 1
  var w = 0.5
  setColor(color)
  if fighter.stats.health > 0 : 
    rectFill(pos.x, pos.y, pos.x + len, pos.y + w)
  setColor(0)

proc ground_primitive() =
  var bottom = fighter1.pos.y + 8
  hline(0, bottom, 128)

proc gameUpdate(dt: float32) =
  elapsed += dt
  if elapsed >= reset_on : elapsed = 0.0
  
  # wrap this shit in a procedure later
  # TODO reverse agility value, should be faster when higher
  if elapsed >= rand(fighter1.stats.agility) and not knock_out(fighter1):
    fighter1.decision = random_action()
    check_distance(fighter1, fighter2)
    decide(fighter1, fighter2)

  if elapsed >= rand(fighter2.stats.agility) and not knock_out(fighter2):
    fighter2.decision = random_action()
    check_distance(fighter2, fighter1)
    decide(fighter2, fighter1)

proc draw_fighter(fighter:Fighter, tint_once:bool = true) =
  setSpritesheet fighter.index
  if fighter.tint_duration > 0 : fighter.tint_duration -= 1
  elif fighter.tint_duration <= 0 : fighter.tint = false
  if fighter.tint : pal(16,8)
  spr(fighter.frame, fighter.pos.x, fighter.pos.y)
  pal()

proc helpfuls_draw() =
  print($fighter1.decision, 0,0)
  print($fighter2.decision, 90,0)
  print($fighter1.distance_from_opp, 0,6)
  print($fighter2.distance_from_opp, 90,6)

proc gameDraw() =
  cls 6
  helpfuls_draw()
  ground_primitive()
  health_bar(fighter1, 12)
  health_bar(fighter2, 8)
  draw_fighter fighter1
  draw_fighter fighter2

nico.init(orgName, appName)
nico.createWindow(appName, 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
