//
//  KillNetFiltersViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "KillNetFiltersViewController.h"
#import "TitleCellView.h"
#import "UITableViewCell+Nib.h"
#import "EVEKillNetAPI.h"
#import "EVEDBAPI.h"

@interface KillNetFiltersViewController ()
@property (nonatomic, retain) NSMutableArray* filters;
@property (nonatomic, retain) NSMutableDictionary* filter;
@end

@implementation KillNetFiltersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Search Criteria";
	self.filters = [NSMutableArray arrayWithObjects:
					@{@"title" : @"Start Date", @"filterType" : @(KillNetFilterTypeStartDate), @"key" : EVEKillNetLogFilterStartDate},
					@{@"title" : @"End Date", @"filterType" : @(KillNetFilterTypeEndDate), @"key" : EVEKillNetLogFilterEndDate},
					@{@"title" : @"Solar System", @"filterType" : @(KillNetFilterTypeSolarSystem), @"key" : EVEKillNetLogFilterSystem},
					@{@"title" : @"Region", @"filterType" : @(KillNetFilterTypeRegion), @"key" : EVEKillNetLogFilterRegion},
					@{@"title" : @"Victim Pilot", @"filterType" : @(KillNetFilterTypeVictimPilot), @"key" : EVEKillNetLogFilterVictimPilot},
					@{@"title" : @"Victim Corp", @"filterType" : @(KillNetFilterTypeVictimCorp), @"key" : EVEKillNetLogFilterVictimCorp},
					@{@"title" : @"Victim Alliance", @"filterType" : @(KillNetFilterTypeVictimAlliance), @"key" : EVEKillNetLogFilterVictimAlliance},
					@{@"title" : @"Victim Ship", @"filterType" : @(KillNetFilterTypeVictimShip), @"key" : EVEKillNetLogFilterVictimShip},
					@{@"title" : @"Victim Ship Class", @"filterType" : @(KillNetFilterTypeVictimShipClass), @"key" : EVEKillNetLogFilterVictimShipClass},
					@{@"title" : @"Attacker Pilot", @"filterType" : @(KillNetFilterTypeAttackerPilot), @"key" : EVEKillNetLogFilterInvolvedPilot},
					@{@"title" : @"Attacker Corp", @"filterType" : @(KillNetFilterTypeAttackerCorp), @"key" : EVEKillNetLogFilterInvolvedCorp},
					@{@"title" : @"Attacker Alliance", @"filterType" : @(KillNetFilterTypeAttackerAlliance), @"key" : EVEKillNetLogFilterInvolvedAlliance},
					@{@"title" : @"Attacker Ship", @"filterType" : @(KillNetFilterTypeAttackerShip), @"key" : EVEKillNetLogFilterInvolvedShip},
					@{@"title" : @"Attacker Ship Class", @"filterType" : @(KillNetFilterTypeAttackerShipClass), @"key" : EVEKillNetLogFilterInvolvedShipClass},
					@{@"title" : @"Combined Pilot", @"filterType" : @(KillNetFilterTypeCombinedPilot), @"key" : EVEKillNetLogFilterCombinedPilot},
					@{@"title" : @"Combined Corp", @"filterType" : @(KillNetFilterTypeCombinedCorp), @"key" : EVEKillNetLogFilterCombinedCorp},
					@{@"title" : @"Combined Alliance", @"filterType" : @(KillNetFilterTypeCombinedAlliance), @"key" : EVEKillNetLogFilterCombinedAlliance},
					nil];

	for (NSDictionary* usedFilter in self.usedFilters) {
		NSInteger i = 0;
		KillNetFilterType filterType = [[usedFilter valueForKey:@"filterType"] integerValue];
		for (NSDictionary* filter in self.filters) {
			if ([[filter valueForKey:@"filterType"] integerValue] == filterType)
				break;
			i++;
		}
		if (self.filters.count > i)
			[self.filters removeObjectAtIndex:i];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TitleCellView";
    TitleCellView *cell = (TitleCellView*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell)
		cell = [TitleCellView cellWithNibName:@"TitleCellView" bundle:nil reuseIdentifier:CellIdentifier];
    cell.titleLabel.text = [[self.filters objectAtIndex:indexPath.row] valueForKey:@"title"];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.filter = [NSMutableDictionary dictionaryWithDictionary:[self.filters objectAtIndex:indexPath.row]];
	KillNetFilterType filterType = [[self.filter valueForKey:@"filterType"] integerValue];
	
	switch (filterType) {
		case KillNetFilterTypeVictimShip:
		case KillNetFilterTypeAttackerShip:
		case KillNetFilterTypeCombinedShip: {
			KillNetFilterShipsViewController* controller = [[KillNetFilterShipsViewController alloc] initWithNibName:@"FittingItemsViewController" bundle:nil];
			controller.delegate = self;
			controller.title = [self.filter valueForKey:@"title"];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			break;
		}
		case KillNetFilterTypeSolarSystem: {
			KillNetFilterSolarSystemsViewController* controller = [[KillNetFilterSolarSystemsViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
			controller.delegate = self;
			controller.title = [self.filter valueForKey:@"title"];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			break;
		}
		case KillNetFilterTypeRegion: {
			KillNetFilterRegionsViewController* controller = [[KillNetFilterRegionsViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
			controller.groupsRequest = nil;
			controller.delegate = self;
			controller.title = [self.filter valueForKey:@"title"];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			break;
		}
		case KillNetFilterTypeVictimShipClass:
		case KillNetFilterTypeAttackerShipClass: {
			KillNetFilterShipClassesViewController* controller = [[KillNetFilterShipClassesViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
			controller.delegate = self;
			controller.title = [self.filter valueForKey:@"title"];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			break;
		}
		case KillNetFilterTypeStartDate:
		case KillNetFilterTypeEndDate: {
			KillNetFilterDateViewController* controller = [[KillNetFilterDateViewController alloc] initWithNibName:@"KillNetFilterDateViewController" bundle:nil];
			controller.title = [self.filter valueForKey:@"title"];
			controller.maximumDate = [NSDate date];
			controller.date = [self.filter valueForKey:@"value"];
			controller.delegate = self;
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			break;
		}
		default:
			[self.delegate killNetFiltersViewController:self didSelectFilter:[self.filters objectAtIndex:indexPath.row]];
			break;
	}
	
}

- (void)dealloc {
	[_tableView release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTableView:nil];
	[super viewDidUnload];
}

#pragma mark - FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	if (type) {
		[self.filter setValue:type.typeName forKey:@"value"];
		[self.delegate killNetFiltersViewController:self didSelectFilter:self.filter];
	}
}

#pragma mark - KillNetFilterDBViewControllerDelegate

- (void) killNetFilterDBViewController:(KillNetFilterDBViewController*) controller didSelectItem:(NSDictionary*) item {
	[self.filter setValue:[item valueForKey:@"name"] forKey:@"value"];
	[self.delegate killNetFiltersViewController:self didSelectFilter:self.filter];
}

#pragma mark - KillNetFilterDateViewControllerDelegate

- (void) killNetFilterDateViewController:(KillNetFilterDateViewController*) controller didSelectDate:(NSDate*) date {
	[self.filter setValue:date forKey:@"value"];
	[self.delegate killNetFiltersViewController:self didSelectFilter:self.filter];
}

@end
