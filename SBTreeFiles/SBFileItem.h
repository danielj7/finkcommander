

#import <Foundation/Foundation.h>

@interface SBFileItem: NSObject
{
    NSArray *_sbchildren;
    NSString *_sbpath;
    NSString *_sbfilename;
    unsigned long long _sbsize;
    NSDate *_sbcdate;
    NSDate *_sbmdate;
}

/* 
Item Creation 
*/

-(id)initWithPath:(NSString *)p;

/* 
Accessors 
*/

-(NSArray *)children;
-(void)setChildren:(NSArray *)c;

-(NSString *)path;
-(void)setPath:(NSString *)p;

-(NSString *)filename;
-(void)setFilename:(NSString *)fn;

-(unsigned long)size;
-(void)setSize:(unsigned long)n;

/* Not used yet:
-(NSDate *)cdate;
-(void)setCdate:(NSDate *)newCdate;
*/

- (NSDate *)mdate;
- (void)setMdate:(NSDate *)newMdate;

/*
Family Ties
*/

-(BOOL)addChild:(SBFileItem *)item;

-(int)numberOfChildren;

-(BOOL)hasChild:(SBFileItem *)item;

-(SBFileItem *)childAtIndex:(int)n;

-(SBFileItem *)childWithPath:(NSString *)iPath;

-(NSString *)pathToParent;

@end
