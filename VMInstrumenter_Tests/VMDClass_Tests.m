SPEC_BEGIN(VMDClass_Tests)

describe(@"VMDClass", ^{
    context(@"when creating a wrapper", ^{
        it(@"Should not return nil if a class is specified", ^{
            
        });
        
        it(@"Should return nil if a class is not specified", ^{
            
        });
    });
    
    context(@"when adding a new method", ^{
        it(@"should raise when arguments are not valid", ^{
            
        });
        
        it(@"Should correctly add a new method otherwise", ^{
            
        });
    });
    
    context(@"when getting a VMDMethod", ^{
        it(@"Should return nil if the method doesn't exist", ^{
            
        });
        
        it(@"Should return a valid VMDMethod for instance methods", ^{
            
        });
        
        it(@"Should return a valid VMDMethod for class methods", ^{
            
        });
    });
    
    context(@"when getting a class method", ^{
        it(@"Should return nil if the method is not valid", ^{
            
        });
        
        it(@"Should return nil if the parameter is an instance method", ^{
            
        });
        
        it(@"Should return a valid VMDMethod otherwise", ^{
            
        });
    });
    
    context(@"when getting an instance method", ^{
        it(@"Should return nil if the method is not valid", ^{
            
        });
        
        it(@"Should return nil if the parameter is a class method", ^{
            
        });
        
        it(@"Should return a valid VMDMethod otherwise", ^{
            
        });
    });
    
    context(@"when checking if the method is an instance or a class method", ^{
        it(@"Should correctly return if the method is an instance method", ^{
            
        });
        
        it(@"Should correctly return if the method is a class method", ^{
            
        });
        
        it(@"Should return NO if the method doesn't belong to the class", ^{
            //2 tests here
        });
    });
    
    context(@"when getting properties", ^{
        it(@"should correctly return the method list", ^{
        
        });
        
        it(@"should correctly return the ivars list", ^{
            
        });
        
        it(@"should correctly return the properties list", ^{
        
        });
        
        it(@"should correctly return the metaclass", ^{
            
        });
        
        it(@"should correctly return the underlying Class value", ^{
           
        });
    });
});

SPEC_END