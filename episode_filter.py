#!/usr/bin/python
import json
import argparse

parser = argparse.ArgumentParser(description='list skills and card IDs by episode.')
parser.add_argument('episodes', metavar='E', type=str, nargs='+',
                      help='an episode m9m9m9')
parser.add_argument('--id-only', action='store_true',
                     help='print the ids only')
parser.add_argument('--skill-only', action='store_true',
                     help='print the skills only')
args = vars(parser.parse_args())

swogi = json.loads(open('swogi.json','r').read())
if len(args["episodes"]) == 0:
	print "please add an episode number as an argument.  valid eps are: [u'EP0', u'EP2', u'EP11', \
	u'EP10', u'EX3', u'UE1', u'EX5', u'EP17', u'EP6', u'EP19', u'UE5', u'EX2', u'EP1', u'EP5', u'EP3', \
	u'EX4', u'EP13', u'EP18', u'EP16', u'EP8', u'EP12', u'UE4', u'UE2', u'EP14', u'UE3', u'EP15', \
	u'EPM', u'EP9', u'EX6', u'EX1', u'EP7', u'EP4']"
	sys.exit()
eps = set(args["episodes"])
id_only = args["id_only"]
skill_only = args["skill_only"]

def display_info(card):
  if card["type"]=="Follower":
    print card['id'].ljust(7), card['name'].ljust(40), str(card['skills'])
  else:
    print card['id'].ljust(7), card['name'].ljust(40), str(card['skills'])

characters = []
spells = []
followers = []
materials = []
skills = set()
id2card = swogi['id_to_card']

for key in id2card.keys():
	if id2card[key]['episode'] in eps:
		if id2card[key]['type'] == 'Character':
			characters.append(id2card[key])
		elif id2card[key]['type'] == 'Spell':
			spells.append(id2card[key])
		elif id2card[key]['type'] == 'Follower':
			followers.append(id2card[key])
			skills |= set(id2card[key]["skills"])
		elif id2card[key]['type'] == 'Material':
			materials.append(id2card[key])
		else:
			print id2card[key]['type']

characters.sort(key=lambda card: card['id'])
spells.sort(key=lambda card: card['id'])
followers.sort(key=lambda card: card['id'])

if not (skill_only or id_only):
  print "Showing cards from episode", eps
  print '\n', "characters:".ljust(48), "skills:"
  for character in characters:
    display_info(character)
  print '\n', "spells:".ljust(48), "skills:"
  for spell in spells:
    display_info(spell)
  print '\n', "followers:".ljust(48), "skills:"
  for follower in followers:
    display_info(follower)

if skill_only:
  for skill in sorted(list(skills)):
    print skill

if id_only:
  for card in characters+spells+(materials if not skill_only else [])+(followers if not skill_only else []):
  #for card in materials:
    print card["id"]
