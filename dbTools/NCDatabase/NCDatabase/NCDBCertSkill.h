//
//  NCDBCertSkill.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBInvType;

@interface NCDBCertSkill : NSManagedObject

@property (nonatomic) int16_t skillLevel;
@property (nonatomic, retain) NCDBInvType *type;
@property (nonatomic, retain) NCDBCertMastery *mastery;

@end
