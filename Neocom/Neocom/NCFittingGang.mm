//
//  NCFittingGang.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingGang.h"
#import "NCFittingProtected.h"

@implementation NCFittingGang

- (nonnull NCFittingCharacter*) addPilot {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	auto pilot = gang->addPilot();
	[self.engine updateWithItem: self];
	return (NCFittingCharacter*) [NCFittingItem item: pilot withEngine:self.engine];
}

- (void) removePilot:(nonnull NCFittingCharacter*) character {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	auto pilot = std::dynamic_pointer_cast<dgmpp::Character>(character.item);
	[self.engine assignIdentifier:nil forItem:[NCFittingItem item: pilot withEngine:self.engine]];
	gang->removePilot(pilot);
	[self.engine updateWithItem: self];
}

- (nonnull NSArray<NCFittingCharacter*>*) pilots {
	NCVerifyFittingContext(self.engine);
	NSMutableArray* array = [NSMutableArray new];
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	for (auto pilot: gang->getPilots()) {
		[array addObject:(NCFittingCharacter*) [NCFittingItem item: pilot withEngine:self.engine]];
	}
	return array;
}

- (nullable NCFittingCharacter*) fleetBooster {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	return gang->getFleetBooster() ? (NCFittingCharacter*) [NCFittingItem item: gang->getFleetBooster() withEngine:self.engine] : nil;
}

- (void) setFleetBooster:(nullable NCFittingCharacter*) fleetBooster {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (fleetBooster)
		gang->setFleetBooster(std::dynamic_pointer_cast<dgmpp::Character>(fleetBooster.item));
	else
		gang->removeFleetBooster();
	[self.engine updateWithItem: self];
}

- (nullable NCFittingCharacter*) wingBooster {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	return gang->getWingBooster() ? (NCFittingCharacter*) [NCFittingItem item: gang->getWingBooster() withEngine:self.engine] : nil;
}

- (void) setWingBooster:(NCFittingCharacter *) wingBooster {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (wingBooster)
		gang->setWingBooster(std::dynamic_pointer_cast<dgmpp::Character>(wingBooster.item));
	else
		gang->removeWingBooster();
	[self.engine updateWithItem: self];
}

- (nullable NCFittingCharacter*) squadBooster {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	return gang->getSquadBooster() ? (NCFittingCharacter*) [NCFittingItem item: gang->getSquadBooster() withEngine:self.engine] : nil;
}

- (void) setSquadBooster:(NCFittingCharacter *) squadBooster {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (squadBooster)
		gang->setSquadBooster(std::dynamic_pointer_cast<dgmpp::Character>(squadBooster.item));
	else
		gang->removeSquadBooster();
	[self.engine updateWithItem: self];
}


@end