
#import <Foundation/Foundation.h>

@interface Base64 : NSObject
+ (NSString *)encode:(NSData *)plainText;
+ (NSString *)encodeString:(NSString*)aString;
@end
