//
//  NCFittingDamagePatternsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingDamagePatternsViewController.h"
#import "NCFittingDamagePatternCell.h"
#import "NCFittingDamagePatternEditorViewController.h"
#import "NCStorage.h"
#import "NCFittingNPCPickerViewController.h"
#import "UIColor+Neocom.h"

@interface NCFittingDamagePatternsViewController ()
@property (nonatomic, strong) NSMutableArray* customDamagePatterns;
@property (nonatomic, strong) NSArray* builtInDamagePatterns;
@property (nonatomic, assign) BOOL unwindOnAppear;
@end

@implementation NCFittingDamagePatternsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.refreshControl = nil;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	NCStorage* storage = [NCStorage sharedStorage];
	NSMutableArray* builtInDamagePatterns = [NSMutableArray new];
	for (NSDictionary* dic in [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"damagePatterns" ofType:@"plist"]]) {
		NCDamagePattern* damagePattern = [[NCDamagePattern alloc] initWithEntity:[NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:storage.managedObjectContext]
												  insertIntoManagedObjectContext:nil];
		damagePattern.name = dic[@"name"];
		damagePattern.em = [dic[@"em"] floatValue];
		damagePattern.kinetic = [dic[@"kinetic"] floatValue];
		damagePattern.thermal = [dic[@"thermal"] floatValue];
		damagePattern.explosive = [dic[@"explosive"] floatValue];
		[builtInDamagePatterns addObject:damagePattern];
	}
	self.builtInDamagePatterns = builtInDamagePatterns;
	self.customDamagePatterns = [[storage damagePatterns] mutableCopy];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (self.unwindOnAppear)
		[self performSegueWithIdentifier:@"Unwind" sender:nil];
}

- (void) dealloc {
	[[NCStorage sharedStorage] saveContext];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	if (editing == self.editing)
		return;
	
	[super setEditing:editing animated:animated];
	double delayInSeconds = 0.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.customDamagePatterns.count inSection:1];
		if (editing)
			[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
		else
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
	});
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingDamagePatternEditorViewController"]) {
		NCFittingDamagePatternEditorViewController* destinationViewController = segue.destinationViewController;
		NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
		NCDamagePattern* damagePattern;
		if (indexPath.section == 1) {
			if (indexPath.row == self.customDamagePatterns.count) {
				NCStorage* storage = [NCStorage sharedStorage];
				
				damagePattern = [[NCDamagePattern alloc] initWithEntity:[NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:storage.managedObjectContext]
										 insertIntoManagedObjectContext:storage.managedObjectContext];
				damagePattern.name = [NSString stringWithFormat:NSLocalizedString(@"Damage Pattern %d", nil), (int32_t)(self.customDamagePatterns.count + 1)];
				damagePattern.em = 0.25;
				damagePattern.kinetic = 0.25;
				damagePattern.thermal = 0.25;
				damagePattern.explosive = 0.25;
				[self.customDamagePatterns addObject:damagePattern];
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.customDamagePatterns.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
			}
			else {
				damagePattern = self.customDamagePatterns[indexPath.row];
			}
		}
		else {
			NCDamagePattern* builtInDamagePattern = self.builtInDamagePatterns[indexPath.row];
			damagePattern = [[NCDamagePattern alloc] initWithEntity:builtInDamagePattern.entity insertIntoManagedObjectContext:[[NCStorage sharedStorage] managedObjectContext]];
			damagePattern.name = builtInDamagePattern.name;
			damagePattern.em = builtInDamagePattern.em;
			damagePattern.kinetic = builtInDamagePattern.kinetic;
			damagePattern.thermal = builtInDamagePattern.thermal;
			damagePattern.explosive = builtInDamagePattern.explosive;
			[self.customDamagePatterns addObject:damagePattern];
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.customDamagePatterns.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
		}
		destinationViewController.damagePattern = damagePattern;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	else if (section == 1)
		return self.customDamagePatterns.count + (self.editing ? 1 : 0);
	else
		return self.builtInDamagePatterns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuItem0Cell"];
		return cell;
	}
	else {
		if (indexPath.section == 1 && indexPath.row == self.customDamagePatterns.count) {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
			//cell.textLabel.text = NSLocalizedString(@"Add Damage Pattern", nil);
			return cell;
		}
		else {
			NCDamagePattern* damagePattern;
			if (indexPath.section == 1)
				damagePattern = self.customDamagePatterns[indexPath.row];
			else
				damagePattern = self.builtInDamagePatterns[indexPath.row];
			
			NCFittingDamagePatternCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingDamagePatternCell"];
			
			cell.emLabel.text = [NSString stringWithFormat:@"%.0f%%", damagePattern.em * 100];
			cell.kineticLabel.text = [NSString stringWithFormat:@"%.0f%%", damagePattern.kinetic * 100];
			cell.thermalLabel.text = [NSString stringWithFormat:@"%.0f%%", damagePattern.thermal * 100];
			cell.explosiveLabel.text = [NSString stringWithFormat:@"%.0f%%", damagePattern.explosive * 100];
			
			cell.emLabel.progress = damagePattern.em;
			cell.kineticLabel.progress = damagePattern.kinetic;
			cell.thermalLabel.progress = damagePattern.thermal;
			cell.explosiveLabel.progress = damagePattern.explosive;
			
			cell.titleLabel.text = damagePattern.name;
			return cell;
		}
	}
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else if (section == 1)
		return NSLocalizedString(@"Custom", nil);
	else
		return NSLocalizedString(@"Predefined", nil);
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		if (indexPath.row == self.customDamagePatterns.count)
			return UITableViewCellEditingStyleInsert;
		else
			return UITableViewCellEditingStyleDelete;
	}
	else
		return UITableViewCellEditingStyleNone;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCDamagePattern* damagePattern = self.customDamagePatterns[indexPath.row];
		[self.customDamagePatterns removeObjectAtIndex:indexPath.row];
		[damagePattern.managedObjectContext deleteObject:damagePattern];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self performSegueWithIdentifier:@"NCFittingDamagePatternEditorViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	}
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor appearanceTableViewCellBackgroundColor];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 || (indexPath.section == 1 && indexPath.row == self.customDamagePatterns.count))
		return 37;
	else
		return 44;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 1;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section > 0) {
		if (self.editing) {
			[self performSegueWithIdentifier:@"NCFittingDamagePatternEditorViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
		}
		else {
			if (indexPath.section == 1)
				self.selectedDamagePattern = self.customDamagePatterns[indexPath.row];
			else
				self.selectedDamagePattern = self.builtInDamagePatterns[indexPath.row];
			[self performSegueWithIdentifier:@"Unwind" sender:[tableView cellForRowAtIndexPath:indexPath]];
		}
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	return @(section);
}

#pragma mark - Private

- (IBAction)unwindFromNPCPicker:(UIStoryboardSegue*)segue {
	NCFittingNPCPickerViewController* sourceViewController = segue.sourceViewController;
	NCDBInvType* type = sourceViewController.selectedNPCType;
	NCStorage* storage = [NCStorage sharedStorage];
	
	NCDamagePattern* damagePattern = [[NCDamagePattern alloc] initWithEntity:[NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:storage.managedObjectContext]
											  insertIntoManagedObjectContext:storage.managedObjectContext];
	
	damagePattern.name = type.typeName;
	
	NCDBDgmTypeAttribute* emDamageAttribute = type.attributesDictionary[@(114)];
	NCDBDgmTypeAttribute* explosiveDamageAttribute = type.attributesDictionary[@(116)];
	NCDBDgmTypeAttribute* kineticDamageAttribute = type.attributesDictionary[@(117)];
	NCDBDgmTypeAttribute* thermalDamageAttribute = type.attributesDictionary[@(1180)];
	NCDBDgmTypeAttribute* damageMultiplierAttribute = type.attributesDictionary[@(64)];
	NCDBDgmTypeAttribute* missileDamageMultiplierAttribute = type.attributesDictionary[@(212)];
	NCDBDgmTypeAttribute* missileTypeIDAttribute = type.attributesDictionary[@(507)];
	
	NCDBDgmTypeAttribute* turretFireSpeedAttribute = type.attributesDictionary[@(51)];
	NCDBDgmTypeAttribute* missileLaunchDurationAttribute = type.attributesDictionary[@(506)];
	
	
	//Turrets damage
	
	float emDamageTurret = 0;
	float explosiveDamageTurret = 0;
	float kineticDamageTurret = 0;
	float thermalDamageTurret = 0;
	float intervalTurret = 0;
	
	if (type.effectsDictionary[@(10)] || type.effectsDictionary[@(1086)]) {
		float damageMultiplier = [damageMultiplierAttribute value];
		if (damageMultiplier == 0)
			damageMultiplier = 1;
		
		emDamageTurret = [emDamageAttribute value] * damageMultiplier;
		explosiveDamageTurret = [explosiveDamageAttribute value] * damageMultiplier;
		kineticDamageTurret = [kineticDamageAttribute value] * damageMultiplier;
		thermalDamageTurret = [thermalDamageAttribute value] * damageMultiplier;
		intervalTurret = [turretFireSpeedAttribute value] / 1000.0;
	}
	
	//Missiles damage
	float emDamageMissile = 0;
	float explosiveDamageMissile = 0;
	float kineticDamageMissile = 0;
	float thermalDamageMissile = 0;
	float intervalMissile = 0;
	
	if (type.effectsDictionary[@(569)]) {
		NCDBInvType* missile = [NCDBInvType invTypeWithTypeID:(int32_t)[missileTypeIDAttribute value]];
		if (missile) {
			NCDBDgmTypeAttribute* emDamageAttribute = missile.attributesDictionary[@(114)];
			NCDBDgmTypeAttribute* explosiveDamageAttribute = missile.attributesDictionary[@(116)];
			NCDBDgmTypeAttribute* kineticDamageAttribute = missile.attributesDictionary[@(117)];
			NCDBDgmTypeAttribute* thermalDamageAttribute = missile.attributesDictionary[@(118)];
			
			float missileDamageMultiplier = [missileDamageMultiplierAttribute value];
			if (missileDamageMultiplier == 0)
				missileDamageMultiplier = 1;
			
			emDamageMissile = [emDamageAttribute value] * missileDamageMultiplier;
			explosiveDamageMissile = [explosiveDamageAttribute value] * missileDamageMultiplier;
			kineticDamageMissile = [kineticDamageAttribute value] * missileDamageMultiplier;
			thermalDamageMissile = [thermalDamageAttribute value] * missileDamageMultiplier;
			intervalMissile = [missileLaunchDurationAttribute value] / 1000.0;
			
		}
	}
	
	if (intervalTurret == 0)
		intervalTurret = 1;
	if (intervalMissile == 0)
		intervalMissile = 1;
	
	float emDPSTurret = emDamageTurret / intervalTurret;
	float explosiveDPSTurret = explosiveDamageTurret / intervalTurret;
	float kineticDPSTurret = kineticDamageTurret / intervalTurret;
	float thermalDPSTurret = thermalDamageTurret / intervalTurret;
	float totalDPSTurret = emDPSTurret + explosiveDPSTurret + kineticDPSTurret + thermalDPSTurret;
	
	
	float emDPSMissile = emDamageMissile / intervalMissile;
	float explosiveDPSMissile = explosiveDamageMissile / intervalMissile;
	float kineticDPSMissile = kineticDamageMissile / intervalMissile;
	float thermalDPSMissile = thermalDamageMissile / intervalMissile;
	float totalDPSMissile = emDPSMissile + explosiveDPSMissile + kineticDPSMissile + thermalDPSMissile;
	
	float emDPS = emDPSTurret + emDPSMissile;
	float explosiveDPS = explosiveDPSTurret + explosiveDPSMissile;
	float kineticDPS = kineticDPSTurret + kineticDPSMissile;
	float thermalDPS = thermalDPSTurret + thermalDPSMissile;
	float totalDPS = totalDPSTurret + totalDPSMissile;
	
	if (totalDPS == 0) {
		damagePattern.em = 0.25;
		damagePattern.kinetic = 0.25;
		damagePattern.thermal = 0.25;
		damagePattern.explosive = 0.25;
	}
	else {
		damagePattern.em = emDPS / totalDPS;
		damagePattern.thermal = thermalDPS / totalDPS;
		damagePattern.kinetic = kineticDPS / totalDPS;
		damagePattern.explosive = explosiveDPS / totalDPS;
	}
	self.selectedDamagePattern = damagePattern;

	self.unwindOnAppear = YES;
}

@end
