#TODO: Consider making freeze frames
# TODO combos!!
# TODO make stats! 
# TODO add boundaries/wall/ or camera movement mayhaps
#   weight dictates distance_from_opp
#   agility dictates less elapsed reset
#   add specials
import nico
import nico/vec
import std/random, std/sequtils, std/math

const orgName = "fsane"
const appName = "boxsim"

type Direction = enum Left Right

type Corner = enum RedCorner BlueCorner

type Moves = enum 
  Stay 
  Charge
  Retreat
  Defend 
  Attack 
  Dodge
  Knockout
  

type Stats = ref object
  max_health: float32
  health: float32
  strength: float32
  agility: float32
  weight: float32
  speed: float32

type Fighter = ref object
  pos: Vec2f
  corner: Corner
  index: int
  frame: int
  tint: bool
  tint_duration: int
  stats: Stats
  step: int
  facing: Direction
  attack_range: float32
  attack_max_pushback: float32
  keep_away_distance: int
  decision: Moves
  distance_from_opp: float32

var elapsed: float32 = 0.0
var reset_on :float32 = 1.0
var match_end : bool = false
var win_sound_played = false

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



proc knock_out(fighter: Fighter) : bool =
  if fighter.stats.health <= 0 :
    if not win_sound_played :
      sfx(0,1)
      win_sound_played = true
    match_end = true
    fighter.frame = 15
    return true
  return false


proc check_distance(fighter: Fighter, enemy: Fighter) =
  # instead += of pos, we need to define step and have an auto update for it later
  # TODO try mult again after eating
  proc distance() : float32 =
    if fighter.facing == Right : return enemy.pos.x - fighter.pos.x
    if fighter.facing == Left :  return fighter.pos.x - enemy.pos.x

  if fighter.decision == Attack and distance() > fighter.attack_range:
    fighter.decision = Charge
  
  if distance() <= 1: # use boundary/hitbox for this later
    fighter.decision = Retreat

  fighter.distance_from_opp = distance()

proc attack_damage(fighter: Fighter, enemy: Fighter) =
  # i don't know the best math for this but here we go
  var damage = fighter.stats.strength * (rand fighter.stats.weight) # add bonuses if ever, modifier stats
  enemy.stats.health -= damage

proc decide(fighter: Fighter, enemy: Fighter) =
  # TODO charge and retreat should be based on a stat (but still randomized)
  # Charge > Retreat, to a degree dependent on playstyle
  # instead += of pos, we need to define step and have an auto update for it later
  var mult = 1.0;
  if fighter.facing == Left:
    mult = -mult
  case fighter.decision
  of Charge: 
    if fighter.facing == Left:
      fighter.pos.x -= rand(2.0)
    elif fighter.facing == Right:
      fighter.pos.x += rand(2.0)
  of Attack: 
    # TODO check for hit/whiff soon
    proc pushback() : float32 = return (fighter.attack_range + rand(2.0) + (rand (fighter.stats.weight / 2)))
    sfx(0, 0)
    attack_damage(fighter, enemy)
    fighter.frame = 2
    enemy.frame = 3
    enemy.tint = true
    enemy.tint_duration = 3
    if enemy.facing == Left:
      enemy.pos.x += pushback()
    elif enemy.facing == Right:
      enemy.pos.x -= pushback()
  of Stay: fighter.frame = 0
  of Retreat: (fighter.pos.x -= rand(2.0) * mult)
  else: discard

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
  #setSpritesheet(1)
  #spr(0, fighter2.pos.x, fighter2.pos.y)
  

nico.init(orgName, appName)
nico.createWindow(appName, 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
