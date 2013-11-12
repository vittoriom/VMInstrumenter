//
//  VMDHelper.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 06/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface VMDHelper : NSObject

+ (NSString *) generatePlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect;
+ (NSString *) generatePlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect;

@end
