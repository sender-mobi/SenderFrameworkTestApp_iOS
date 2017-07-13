//
//  ImagesNamesRotator.m
//  SENDER
//
//  Created by Eugene on 12/8/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "DefaultContactImageGenerator.h"

@implementation DefaultContactImageGenerator

+ (NSString *)convertContactNameToImageName:(NSString *)contactName
{
    if ([contactName length] < 1)
        return @"_#";
    
    NSString * imageName = @"_#";
    
    NSString * firstLetter = [[contactName substringToIndex:1] lowercaseString];
    
    if ([firstLetter isEqualToString:@"a"] || [firstLetter isEqualToString:@"а"]) {
        imageName = @"_A";
    }
    else if ([firstLetter isEqualToString:@"b"] || [firstLetter isEqualToString:@"в"]) {
        imageName = @"_B";
    }
    else if ([firstLetter isEqualToString:@"c"] || [firstLetter isEqualToString:@"с"]) {
        imageName = @"_C";
    }
    else if ([firstLetter isEqualToString:@"d"]) {
        imageName = @"_D";
    }
    else if ([firstLetter isEqualToString:@"e"] || [firstLetter isEqualToString:@"е"]) {
        imageName = @"_E";
    }
    else if ([firstLetter isEqualToString:@"f"]) {
        imageName = @"_F";
    }
    else if ([firstLetter isEqualToString:@"g"]) {
        imageName = @"_G";
    }
    else if ([firstLetter isEqualToString:@"h"] || [firstLetter isEqualToString:@"н"]) {
        imageName = @"_H";
    }
    else if ([firstLetter isEqualToString:@"i"]) {
        imageName = @"_I";
    }
    else if ([firstLetter isEqualToString:@"j"]) {
        imageName = @"_J";
    }
    else if ([firstLetter isEqualToString:@"k"] || [firstLetter isEqualToString:@"к"]) {
        imageName = @"_K";
    }
    else if ([firstLetter isEqualToString:@"l"]) {
        imageName = @"_L";
    }
    else if ([firstLetter isEqualToString:@"m"] || [firstLetter isEqualToString:@"м"]) {
        imageName = @"_M";
    }
    else if ([firstLetter isEqualToString:@"n"]) {
        imageName = @"_N";
    }
    else if ([firstLetter isEqualToString:@"o"] || [firstLetter isEqualToString:@"о"]) {
        imageName = @"_O";
    }
    else if ([firstLetter isEqualToString:@"p"] || [firstLetter isEqualToString:@"р"]) {
        imageName = @"_P";
    }
    else if ([firstLetter isEqualToString:@"q"]) {
        imageName = @"_Q";
    }
    else if ([firstLetter isEqualToString:@"r"]) {
        imageName = @"_R";
    }
    else if ([firstLetter isEqualToString:@"s"]) {
        imageName = @"_S";
    }
    else if ([firstLetter isEqualToString:@"t"] || [firstLetter isEqualToString:@"т"]) {
        imageName = @"_T";
    }
    else if ([firstLetter isEqualToString:@"u"]) {
        imageName = @"_U";
    }
    else if ([firstLetter isEqualToString:@"v"]) {
        imageName = @"_V";
    }
    else if ([firstLetter isEqualToString:@"w"]) {
        imageName = @"_W";
    }
    else if ([firstLetter isEqualToString:@"x"] || [firstLetter isEqualToString:@"х"]) {
        imageName = @"_X";
    }
    else if ([firstLetter isEqualToString:@"y"]) {
        imageName = @"_Y";
    }
    else if ([firstLetter isEqualToString:@"z"]) {
        imageName = @"_Z";
    }
    //RUS SECTION
    else if ([firstLetter isEqualToString:@"д"]) {
        imageName = @"_d-ru";
    }
    else if ([firstLetter isEqualToString:@"ё"]) {
        imageName = @"_e2-ru";
    }
    else if ([firstLetter isEqualToString:@"ф"]) {
        imageName = @"_f-ru";
    }
    else if ([firstLetter isEqualToString:@"г"]) {
        imageName = @"_g-ru";
    }
    else if ([firstLetter isEqualToString:@"ш"]) {
        imageName = @"_h1-ru";
    }
    else if ([firstLetter isEqualToString:@"ч"]) {
        imageName = @"_h-ru";
    }
    else if ([firstLetter isEqualToString:@"ж"]) {
        imageName = @"_j-ru";
    }
    else if ([firstLetter isEqualToString:@"и"]) {
        imageName = @"_i-ru";
    }
    else if ([firstLetter isEqualToString:@"я"]) {
        imageName = @"_I-am-ru";
    }
    else if ([firstLetter isEqualToString:@"й"]) {
        imageName = @"_i1-ru";
    }
    else if ([firstLetter isEqualToString:@"л"]) {
        imageName = @"_l-ru";
    }
    else if ([firstLetter isEqualToString:@"п"]) {
        imageName = @"_P-ru";
    }
    else if ([firstLetter isEqualToString:@"ц"]) {
        imageName = @"_s1-ru";
    }
    else if ([firstLetter isEqualToString:@"у"]) {
        imageName = @"_u-ru";
    }
    else if ([firstLetter isEqualToString:@"ы"]) {
        imageName = @"_w-ru";
    }
    else if ([firstLetter isEqualToString:@"ю"]) {
        imageName = @"_you-ru";
    }
    else if ([firstLetter isEqualToString:@"з"]) {
        imageName = @"_z-ru";
    }
    else if ([firstLetter isEqualToString:@"б"]) {
        imageName = @"_B-ru";
    }
    
    return imageName;
}

@end
