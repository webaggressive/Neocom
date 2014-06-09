//
//  NCDBInvCategory.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvGroup;

@interface NCDBInvCategory : NSManagedObject

@property (nonatomic) int32_t categoryID;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NCDBEveIcon *icon;
@end

@interface NCDBInvCategory (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBInvGroup *)value;
- (void)removeGroupsObject:(NCDBInvGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

@end
