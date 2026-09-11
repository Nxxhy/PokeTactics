"""Explicit ability recipes; no type-based/random assignment. Sources pinned in manifest."""
import json, pathlib
root = pathlib.Path(__file__).resolve().parents[1]
# id: Showdown reference move, choreography, projectile, accent, color, particle count
recipes = {
1:('leechseed','seed','energyball','leaf1','78c850',3),4:('ember','embers','fireball','flareball','f89838',3),
43:('pollenpuff','pollen','petal','poisonwisp','b8d858',5),48:('psychic','pulse','purplewisp','mistball','c888e0',3),
60:('waterpulse','wave','waterwisp','fist','4898e8',3),69:('gigadrain','vine','leaf2','energyball','68b848',4),
74:('protect','rampart','caltrop','gear','b8a068',4),111:('headbutt','ram','fist','gear','b8a890',2),
122:('barrier','mirror','purplewisp','gear','f090b8',4),155:('flamewheel','wheel','fireball','flareball','f88030',6),
161:('superfang','bite','topbite','bottombite','e8d888',2),172:('thunderbolt','chain','electroball','hitmarker','ffe060',4),
173:('moonlight','moon','heart','purplewisp','ffb8d8',5),179:('thunderwave','rings','electroball','energyball','f8d840',3),
238:('icebeam','beam','iceball','mistball','88d8f8',4),255:('doublekick','kick','foot','flareball','f8a060',2),
66:('karatechop','chop','fist','leftslash','d8b078',1),81:('magnetrise','magnet','gear','electroball','a8c8e0',4),
92:('nightmare','nightmare','blackwisp','purplewisp','a878e0',5),95:('earthquake','quake','caltrop','gear','c8a070',5),
120:('wish','star','energyball','heart','f8d888',5),133:('darkpulse','eclipse','blackwisp','rightslash','9878c8',4),
167:('stringshot','web','poisonwisp','caltrop','b090d8',6),170:('charge','lantern','electroball','waterwisp','a8e8f8',2),
174:('hypervoice','voice','mistball','heart','f8a8d0',3),204:('spikes','spikes','caltrop','gear','c0c8a0',6),
218:('lavaplume','lava','fireball','gear','e89048',5),270:('raindance','rain','waterwisp','leaf1','70c8f0',7),
273:('bulletseed','volley','energyball','leaf2','88c858',5),280:('psychic','vortex','purplewisp','energyball','d088e8',6),
285:('machpunch','punch','fist','petal','c0b878',3),298:('aquatail','tail','waterwisp','heart','68c8f8',2),
123:('xscissor','cross','leftslash','rightslash','a0d898',2),143:('rest','sleep','heart','mistball','a8c8b8',3),
200:('perishsong','song','purplewisp','blackwisp','b888e0',5),209:('playrough','tumble','heart','fist','f8b0d0',4),
213:('powertrick','shell','gear','poisonwisp','e8b870',6),215:('nightslash','claw','leftclaw','rightclaw','b0c8f8',3),
220:('powdersnow','snow','iceball','waterwisp','c0e0f0',5),227:('steelwing','wings','feather','leftslash','b8d0e0',4),
228:('crunch','hellbite','topbite','fireball','e08068',3),290:('shadowclaw','phantom','leftclaw','blackwisp','c8b098',2),
296:('seismictoss','throw','fist','mistball','d8b888',4),304:('ironhead','iron','gear','hitmarker','b8c8d8',3),
307:('zenheadbutt','zen','purplewisp','fist','e8a8d0',4),309:('voltswitch','jump','electroball','rightslash','e8e868',3),
315:('floralhealing','garden','petal','leaf1','e898c0',7),355:('nightshade','fog','blackwisp','mistball','a898d0',6),
115:('protect','family','heart','gear','e8c898',2),131:('auroraveil','aurora','iceball','mistball','88e8e0',6),
147:('dracometeor','meteor','flareball','energyball','b890f0',5),214:('megahorn','horn','rightclaw','hitmarker','98b8d8',1),
246:('sandstorm','sand','caltrop','mistball','d8c090',7),302:('protect','gem','purplewisp','gear','c898e8',4),
303:('crunch','jaw','topbite','bottombite','d8c068',4),328:('earthpower','rift','caltrop','flareball','c89860',5),
333:('sing','sky','feather','heart','b0e0f8',6),353:('shadowball','curse','blackwisp','rightclaw','b890b8',4),
359:('nightslash','crescent','rightslash','blackwisp','c8d8e8',1),371:('dragonrush','dive','leftclaw','flareball','a098e8',3),
144:('blizzard','blizzard','iceball','feather','a8e8ff',8),145:('thunder','storm','electroball','flareball','ffe878',6),
146:('sacredfire','phoenix','fireball','feather','ffb058',7),243:('wildcharge','hunt','electroball','leftclaw','f8d858',5),
244:('eruption','volcano','flareball','fireball','f89868',7),361:('icywind','frost','iceball','purplewisp','b0e0f8',4),
363:('surf','surf','waterwisp','iceball','80b8e8',6),380:('mistball','mist','mistball','heart','f0a8b8',4),
381:('lusterpurge','luster','energyball','purplewisp','98b8f8',5),384:('hurricane','zenith','feather','energyball','88e8a8',8),
}
roster=json.loads((root/'data/roster.json').read_text(encoding='utf8'))
commit=(root/'docs/showdown-research/commit.txt').read_text()
source=(root/'docs/showdown-research/play.pokemonshowdown.com__src__battle-animations-moves.ts').read_text(encoding='utf8')
output={}
for mon in roster:
 move,pattern,asset,accent,color,count=recipes[mon['id']]
 # Only claim a corresponding Showdown move when actually present (including aliases).
 present=(move+':') in source
 output[str(mon['id'])]=dict(ability=mon['ability'],pattern=pattern,asset=asset,accent=accent,color=color,count=count,
  showdown_move=move if present else None,source='https://github.com/smogon/pokemon-showdown-client/blob/'+commit+'/play.pokemonshowdown.com/src/battle-animations-moves.ts' if present else 'Eigene Choreografie mit CC0-Showdown-Effekten',
  forms=mon['forms'],effects=mon['effects'],variants='Stern 2: zusätzliche Akzente; Stern 3: goldener Doppelring und größere Signatur. Psycho 6/8: violetter Doppelimpuls; echte zusätzliche Ziele und Nachhall aus Kampfevents.')
(root/'data/ability_animations.json').write_text(json.dumps(output,ensure_ascii=False,indent=2),encoding='utf8')
assert len(output)==70 and len({r['pattern'] for r in output.values()})==70
print('70 explicit ability recipes; reference moves verified:',sum(bool(r['showdown_move']) for r in output.values()))
