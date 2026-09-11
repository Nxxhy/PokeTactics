import json,pathlib
P=pathlib.Path(__file__).resolve().parents[1]
A=[]
def add(id,name,text,**kw): A.append(dict(id=id,name=name,description=text,**kw))
add('grant','Reisekasse','Sofort +12 Gold.',gold=12)
add('win_gold','Siegesprämie','Nach jedem Sieg +3 Gold.',win_gold=3)
add('loss_gold','Rückendeckung','Nach jeder Niederlage +4 Gold.',loss_gold=4)
add('saver','Sparvertrag','Ab 50 Gold vor Auszahlung +2 Bonusgold je gewertetem Kampf. Zinsen bleiben maximal 5.',saver=2)
add('xp_round','Feldstudium','Nach jedem gewerteten Kampf +2 EP.',xp_round=2)
add('xp_buy','Lerntempo','EP-Käufe geben 6 statt 4 EP für 4 Gold.',xp_buy=2)
add('free_roll','Frische Auswahl','Ein kostenloser Shopwechsel sofort und nach jedem gewerteten Kampf. Nicht ansparbar.',free_roll=1)
add('discount','Treuerabatt','Der erste Kauf sofort und nach jedem gewerteten Kampf kostet 1 Gold weniger, mindestens 1.',discount=1)
add('dividend','Vielfaltsprämie','Mit mindestens 4 verschiedenen Typen auf dem Feld +2 Gold je gewertetem Kampf.',dividend=2)
add('underdog','Kleines Budget','Mit mindestens 3 verschiedenen Kosten-1-Linien auf dem Feld +3 Gold je gewertetem Kampf.',underdog=3)
for id,name,text,cond,mods in [
 ('front','Vorhut','Start in vorderster eigener Reihe: +25 Rüstung.','front',{'armor':25}),
 ('back','Rückendeckung aus der Ferne','Start in hinterster eigener Reihe: +25 % Fähigkeitsstärke.','back',{'power_pct':.25}),
 ('solo','Einzelkämpfer','Ohne orthogonal benachbarten Verbündeten beim Start: +25 % Angriff.','solo',{'attack_pct':.25}),
 ('neighbors','Schulter an Schulter','Mit orthogonal benachbartem Verbündeten beim Start: +20 % Leben.','neighbors',{'hp_pct':.2}),
 ('edges','Flankenwache','Start in äußerster linker oder rechter Spalte: Schild in Höhe von 25 % maximalem Leben.','edges',{'shield_pct':.25}),
 ('center','Mittelfeld','Start in mittlerer Spalte: +30 Startmana.','center',{'start_mana':30}),
 ('pairs','Doppelaufstellung','Mit einer zweiten Einheit derselben Linie auf dem Feld: +20 % Angriff.','pairs',{'attack_pct':.2}),
 ('mono','Spezialisten','Pokémon mit genau einem Typ: +20 % Leben und +20 Rüstung.','mono',{'hp_pct':.2,'armor':20}),
 ('diverse','Bunte Mannschaft','Bei mindestens 6 verschiedenen Teamtypen: alle +20 % Fähigkeitsstärke.','diverse',{'power_pct':.2}),
 ('lowcost','Kleine Helden','Kosten-1- und Kosten-2-Pokémon: +25 % Leben.','lowcost',{'hp_pct':.25}),
 ('tank_battery','Schmerzspeicher','Tanks: zusätzlich 10 Mana pro Treffer mit Lebensverlust.','Tank',{'hit_mana':10}),
 ('attacker_battery','Angriffsrhythmus','Angreifer: zusätzlich 8 Mana pro normalem Angriff.','Angreifer',{'attack_mana':8}),
 ('mage_battery','Meditation','Magier: zusätzlich 6 Mana pro Sekunde.','Magier',{'passive_mana':6}),
 ('support_battery','Hilfsbereitschaft','Unterstützer: +35 % ausgehende Heilung.','Unterstützer',{'healing':.35})]: add(id,name,text,condition=cond,mods=mods)
for typ,id,name in [('Pflanze','grass_count','Pflanzenbund'),('Feuer','fire_count','Feuerbund'),('Wasser','water_count','Wasserbund'),('Elektro','electric_count','Elektrobund'),('Geist','ghost_count','Geisterbund'),('Stahl','steel_count','Stahlbund')]:
 add(id,name,f'{typ} zählt für Synergieschwellen als eine zusätzliche Linie, sofern mindestens eine echte Linie dieses Typs auf dem Feld steht.',emblem=typ)
for id,name,text,key,value in [
 ('lifesteal','Vampirzahn','Normale Angriffe heilen um 20 % des tatsächlich verursachten Lebensverlusts.','lifesteal',.2),
 ('spell_vamp','Zauberquelle','Fähigkeitsschaden heilt den Anwender um 15 % des tatsächlich verursachten Lebensverlusts.','spell_vamp',.15),
 ('thorns','Dornenschild','Nach gegnerischem normalem Treffer: 25 direkter Rückschaden. Keine Reflexionsketten.','thorns',25),
 ('execute','Vollstrecker','+30 % Schaden gegen Ziele unter 30 % Leben.','execute',.3),
 ('giant','Riesentöter','+25 % Schaden gegen Ziele mit mehr maximalem Leben als der Angreifer.','giant',.25),
 ('firsthit','Eröffnungsschlag','Der erste normale Angriff jedes Pokémon je Kampf verursacht +80 % Rohschaden.','firsthit',.8),
 ('thirdhit','Dreiertakt','Jeder dritte normale Angriff verursacht +60 % Rohschaden.','thirdhit',.6),
 ('splash','Splittertreffer','Normale Angriffe treffen andere Gegner im Radius 1 des Ziels für 20 % Angriff als typisierten Zusatzschaden.','splash',.2),
 ('chain','Kettenfunke','Jeder dritte normale Angriff trifft einen weiteren Gegner für 50 % Angriff als Elektroschaden.','chain',.5),
 ('poison_attack','Giftspitzen','Normale Treffer vergiften für 12 Schaden pro Sekunde über 4 Sekunden.','poison_attack',12),
 ('burn_spell','Nachglut','Schadensfähigkeiten verbrennen getroffene Gegner für 18 Schaden pro Sekunde über 4 Sekunden.','burn_spell',18),
 ('stun_first','Überraschung','Der erste normale Treffer jedes Pokémon betäubt 1 Sekunde.','stun_first',10),
 ('shred_attack','Panzerbrecher','Jeder dritte normale Treffer senkt die Rüstung 4 Sekunden lang um 18.','shred_attack',40),
 ('shield_cast','Schutzzauber','Jede Fähigkeitsauslösung gibt dem Anwender einen Schild in Höhe von 12 % maximalem Leben.','shield_cast',.12),
 ('heal_cast','Heilende Worte','Jede Fähigkeitsauslösung heilt den verletztesten Verbündeten um 8 % seines maximalen Lebens.','heal_cast',.08),
 ('mana_cast','Inspiration','Jede Fähigkeitsauslösung gibt anderen lebenden Verbündeten 5 Mana.','mana_cast',5),
 ('kill_haste','Siegesrausch','Nach einem besiegten Gegner: 4 Sekunden +35 % Angriffstempo.','kill_haste',40),
 ('revive','Zweiter Atem','Jedes Pokémon verhindert einmal pro Kampf seinen Tod und erhält 20 % Leben zurück.','revive',.2),
 ('regen','Erholung','Jede Sekunde heilen lebende Pokémon 1,5 % ihres maximalen Lebens.','regen',.015),
 ('cleanse_tick','Klarer Kopf','Alle 8 Sekunden entfernen eigene Pokémon alle negativen Status.','cleanse_tick',80),
 ('mana_burn','Gedankenraub','Jeder dritte normale Treffer entzieht dem Ziel 15 Mana und gibt dem Angreifer bis zu 15 Mana.','mana_burn',15),
 ('patient','Geduld','Nach 20 Kampfsekunden erhalten eigene Pokémon einmalig +35 % Angriff und Fähigkeitsstärke.','patient',.35)]: add(id,name,text,mods={key:value})
assert len(A)==52
(P/'data/augments.json').write_text(json.dumps(A,ensure_ascii=False,indent=2),encoding='utf-8')
print('Augments:',len(A))
