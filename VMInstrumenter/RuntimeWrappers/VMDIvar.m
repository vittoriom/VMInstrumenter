//
//  VMDIvar.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDIvar.h"

@implementation VMDIvar {
    Ivar _ivar;
}

+ (VMDIvar *) ivarWithIvar:(Ivar)ivar
{
    VMDIvar *ivarObject = [VMDIvar new];
    
    ivarObject->_ivar = ivar;
    
    return ivarObject;
}

- (NSString *) name
{
    const char* ivarName = ivar_getName(_ivar);
    return [NSString stringWithCString:ivarName encoding:NSUTF8StringEncoding];


}

@end
