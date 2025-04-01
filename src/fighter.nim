import nico/vec
import nico
import std/random
var win_sound_played = false

type Moves* = enum 
  Stay 
  Charge
  Retreat
  Defend 
  Attack 
  Dodge
  Knockout
  

type Stats* = ref object
  max_health*: float32
  health*: float32
  strength*: float32
  agility*: float32
  weight*: float32
  speed*: float32

type Direction* = enum Left Right

type Corner* = enum RedCorner BlueCorner

type Fighter* = ref object
  pos*: Vec2f
  corner*: Corner
  index*: int
  frame*: int
  tint*: bool
  tint_duration*: int
  stats*: Stats
  step*: int
  facing*: Direction
  attack_range*: float32
  attack_max_pushback*: float32
  keep_away_distance*: int
  decision*: Moves
  distance_from_opp*: float32

proc knock_out*(fighter: Fighter) : bool =
  if fighter.stats.health <= 0 :
    if not win_sound_played :
      sfx(0,1)
      win_sound_played = true
    fighter.frame = 15
    return true
  return false


proc attack_damage(fighter: Fighter, enemy: Fighter) =
  # i don't know the best math for this but here we go
  var damage = fighter.stats.strength * (rand fighter.stats.weight) # add bonuses if ever, modifier stats
  enemy.stats.health -= damage


proc decide*(fighter: Fighter, enemy: Fighter) =
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

proc check_distance*(fighter: Fighter, enemy: Fighter) =
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
