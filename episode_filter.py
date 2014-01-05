#!/usr/bin/python
import json
import sys

swogi = json.loads(open('swogi.json','r').read())
if len(sys.argv) == 1:
	print "please add an episode number as an argument.  valid eps are: [u'EP0', u'EP2', u'EP11', \
	u'EP10', u'EX3', u'UE1', u'EX5', u'EP17', u'EP6', u'EP19', u'UE5', u'EX2', u'EP1', u'EP5', u'EP3', \
	u'EX4', u'EP13', u'EP18', u'EP16', u'EP8', u'EP12', u'UE4', u'UE2', u'EP14', u'UE3', u'EP15', \
	u'EPM', u'EP9', u'EX6', u'EX1', u'EP7', u'EP4']"
	sys.exit()
ep = sys.argv[1]

def display_info(card):
	print card['id'].ljust(7), card['name'].ljust(40), str(card['skills'])

characters = []
spells = []
followers = []
id2card = swogi['id_to_card']

for key in id2card.keys():
	if id2card[key]['episode'] == ep:
		if id2card[key]['type'] == 'Character':
			characters.append(id2card[key])
		elif id2card[key]['type'] == 'Spell':
			spells.append(id2card[key])
		elif id2card[key]['type'] == 'Follower':
			followers.append(id2card[key])

characters.sort(key=lambda card: card['id'])
spells.sort(key=lambda card: card['id'])
followers.sort(key=lambda card: card['id'])

print "Showing cards from episode", ep
print '\n', "characters:".ljust(48), "skills:"
for character in characters:
	display_info(character)
print '\n', "spells:".ljust(48), "skills:"
for spell in spells:
	display_info(spell)
print '\n', "followers:".ljust(48), "skills:"
for follower in followers:
	display_info(follower)

