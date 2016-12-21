//
//  LAutoLickLabel.m
//  LAutomaticLinkDemo
//
//  Created by 梁海军 on 2016/12/16.
//  Copyright © 2016年 lhj. All rights reserved.
//

#import "LAutoLabel.h"
@interface LAutoLabel()<NSLayoutManagerDelegate>

@property(nonatomic, strong)NSTextStorage *storage;

@property(nonatomic, strong)NSTextContainer *container;

@property(nonatomic, strong)NSLayoutManager *manger;

@property (nonatomic, copy)NSArray *linkRanges;

@property (nonatomic, assign)NSRange selectedRange;

@property (nonatomic, assign) BOOL isTouchMoved;

@property (nonatomic)UIColor *selectedLinkBackgroundColor;

@end

NSString * const LAutoLabelLinkTypeKey = @"linkType";
NSString * const LAutoLabelRangeKey = @"range";
NSString * const LAutoLabelLinkKey = @"link";

@implementation LAutoLabel

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        _container = [[NSTextContainer alloc] init];
        _container.maximumNumberOfLines = self.numberOfLines;
        _container.lineBreakMode = self.lineBreakMode;
        _container.size = self.frame.size;
        _container.lineFragmentPadding = 0;
        
        _storage = [[NSTextStorage alloc] init];
    
  
        _manger = [[NSLayoutManager alloc] init];
        [_manger setTextStorage:_storage];
        [_manger addTextContainer:_container];
        [_storage addLayoutManager:_manger];
        _manger.delegate = self;
        
        self.userInteractionEnabled = YES;
        _selectedLinkBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect{
    
    NSRange glyphRange = [_manger glyphRangeForTextContainer:_container];
    CGPoint glyphsPosition = [self calcGlyphsPositionInView];

    [_manger drawBackgroundForGlyphRange:glyphRange atPoint:glyphsPosition];
    [_manger drawGlyphsForGlyphRange:glyphRange atPoint:glyphsPosition];
}
- (CGPoint)calcGlyphsPositionInView{
    CGPoint textOffset = CGPointZero;
    CGRect textBounds = [_manger usedRectForTextContainer:_container];
    textBounds.size.width = ceil(textBounds.size.width);
    textBounds.size.height = ceil(textBounds.size.height);
    if (textBounds.size.height < self.bounds.size.height){
        CGFloat paddingHeight = (self.bounds.size.height - textBounds.size.height) / 2.0;
        textOffset.y = paddingHeight;
    }
    return textOffset;
}
#pragma mark - setter
-(void)setText:(NSString *)text{
    [super setText:text];
    if (!text) text = @"";
    [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:text attributes:[self attributesProperties]]];
}

-(void)setAttributedText:(NSAttributedString *)attributedText{
    [super setAttributedText:attributedText];
    [self updateTextStoreWithAttributedString:attributedText];
}


-(void)setNumberOfLines:(NSInteger)numberOfLines{
    [super setNumberOfLines: numberOfLines];
    _container.maximumNumberOfLines = 0;
}

-(void)setLineBreakMode:(NSLineBreakMode)lineBreakMode{
    [super setLineBreakMode:lineBreakMode];
    [_container setLineBreakMode:lineBreakMode];
}

-(void)setSelectedRange:(NSRange)range{
    
    if (self.selectedRange.length && !NSEqualRanges(self.selectedRange, range))
        [_storage removeAttribute:NSBackgroundColorAttributeName range:self.selectedRange];
    if (range.length)
        [_storage addAttribute:NSBackgroundColorAttributeName value:_selectedLinkBackgroundColor range:range];
    _selectedRange = range;
    [self setNeedsDisplay];
}

#pragma mark - private
- (void)updateTextStoreWithAttributedString:(NSAttributedString *)attributedString{
    if (attributedString.length != 0){
        self.linkRanges = [self rangesForLink:attributedString];
        attributedString = [self addLinkAttributesToAttributedString:attributedString linkRanges:self.linkRanges];
    }else{
        self.linkRanges = nil;
    }
    [_storage setAttributedString:attributedString];
  
}

- (NSArray *)rangesForLink:(NSAttributedString *)text{
    NSMutableArray *ranges = [[NSMutableArray alloc] init];
    [ranges addObjectsFromArray:[self rangesForUserHandle:text.string]];
    [ranges addObjectsFromArray:[self rangesForHashTag:text.string]];
    [ranges addObjectsFromArray:[self rangesForURL:self.attributedText]];
    return ranges;
}

- (NSAttributedString *)addLinkAttributesToAttributedString:(NSAttributedString *)string linkRanges:(NSArray *)linkRanges{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    for (NSDictionary *dictionary in linkRanges){
        NSRange range = [[dictionary objectForKey:LAutoLabelRangeKey] rangeValue];
        NSDictionary *attributes = @{NSForegroundColorAttributeName : self.tintColor};
        [attributedString addAttributes:attributes range:range];
        if([dictionary[LAutoLabelLinkTypeKey] unsignedIntegerValue] == LAutoTypeURL){
        [attributedString addAttribute:NSLinkAttributeName value:dictionary[LAutoLabelLinkKey] range:range];
        }
    }
    return attributedString;
}



- (NSArray *)rangesForUserHandle:(NSString *)text{
    NSMutableArray *ranges = [[NSMutableArray alloc] init];
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        regex = [[NSRegularExpression alloc]initWithPattern:@"(?<!\\w)@([\\w\\_]+)?" options:0 error:&error];
    });
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches){
        NSRange matchRange = [match range];
        NSString *matchString = [text substringWithRange:matchRange];
        [ranges addObject:@{LAutoLabelLinkTypeKey : @(LAutoTypeUserHandle),
                                         LAutoLabelRangeKey : [NSValue valueWithRange:matchRange],
                                          LAutoLabelLinkKey : matchString
                                          }];
    }
    
    return ranges;
}

- (NSArray *)rangesForHashTag:(NSString *)text{
    NSMutableArray *ranges = [[NSMutableArray alloc] init];
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        regex = [[NSRegularExpression alloc]initWithPattern:@"(?<!\\w)#([\\w\\_]+)?" options:0 error:&error];
    });
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches){
        NSRange matchRange = [match range];
        NSString *matchString = [text substringWithRange:matchRange];
        [ranges addObject:@{LAutoLabelLinkTypeKey : @(LAutoTypeHashTag),
                            LAutoLabelRangeKey : [NSValue valueWithRange:matchRange],
                            LAutoLabelLinkKey : matchString
                            }];
    }
    
    return ranges;
}

- (NSArray *)rangesForURL:(NSAttributedString *)text{
    NSMutableArray *ranges = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:&error];
    NSString *plainText = text.string;
    NSArray *matches = [detector matchesInString:plainText
                                         options:0
                                           range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches){
        NSRange matchRange = [match range];
        NSString *realURL = [text attribute:NSLinkAttributeName atIndex:matchRange.location effectiveRange:nil];
        if (realURL == nil) realURL = [plainText substringWithRange:matchRange];
        if ([match resultType] == NSTextCheckingTypeLink)
        {
            [ranges addObject:@{LAutoLabelLinkTypeKey : @(LAutoTypeURL),
                                       LAutoLabelRangeKey : [NSValue valueWithRange:matchRange],
                                       LAutoLabelLinkKey : realURL,
                                       }];
        }
    }
    return ranges;
}

-(NSDictionary *)attributesProperties{
    NSShadow *shadow = shadow = [[NSShadow alloc] init];
    if (self.shadowColor)
    {
        shadow.shadowColor = self.shadowColor;
        shadow.shadowOffset = self.shadowOffset;
    }
    else
    {
        shadow.shadowOffset = CGSizeMake(0, -1);
        shadow.shadowColor = nil;
    }
    UIColor *color = self.textColor;
    if (!self.isEnabled)
    {
        color = [UIColor lightGrayColor];
    }
    else if (self.isHighlighted)
    {
        color = self.highlightedTextColor;
    }
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = self.textAlignment;
    NSDictionary *attributes = @{NSFontAttributeName : self.font,
                                 NSForegroundColorAttributeName : color,
                                 NSShadowAttributeName : shadow,
                                 NSParagraphStyleAttributeName : paragraph,
                                 };
    return attributes;
}

-(NSDictionary *)linkAtPoint:(CGPoint)location{
    CGPoint offset = [self calcGlyphsPositionInView];
    location.x -= offset.x;
    location.y -= offset.y;
    NSRange lineRange;
    NSUInteger touchIndex = [_manger glyphIndexForPoint:location inTextContainer:_container];
    CGRect lineRect = [_manger lineFragmentUsedRectForGlyphAtIndex:touchIndex effectiveRange:&lineRange];
    if (CGRectContainsPoint(lineRect, location) == NO) return nil;
    for (NSDictionary *dictionary in self.linkRanges){
        NSRange range = [[dictionary objectForKey:LAutoLabelRangeKey] rangeValue];
        if ((touchIndex >= range.location) && touchIndex < (range.location + range.length))
        {
            return dictionary;
        }
    }
    return nil;
}

#pragma mark - NSLayoutManagerDelegate
-(BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex{
    NSRange range;
    NSURL *url = [layoutManager.textStorage attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&range];
    return !(url&&range.location<charIndex&&NSMaxRange(range)>=charIndex);
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    _isTouchMoved = NO;
    CGPoint point = [[touches anyObject] locationInView:self];
    NSDictionary *link = [self linkAtPoint:point];
    if (link) {
       self.selectedRange = [[link objectForKey:LAutoLabelRangeKey] rangeValue];
    }
    else{
     [super touchesBegan:touches withEvent:event];   
    }
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    if (_isTouchMoved){
        self.selectedRange = NSMakeRange(0, 0);
        return;
    }
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    NSDictionary *link  = [self linkAtPoint:touchLocation];
    if (link){
        NSRange range = [[link objectForKey:LAutoLabelRangeKey] rangeValue];
        NSString *touchedSubstring = [link objectForKey:LAutoLabelLinkKey];
        LAutoLinkType linkType = (LAutoLinkType)[[link objectForKey:LAutoLabelLinkKey] intValue];
        switch (linkType) {
            case LAutoTypeUserHandle:
                if ([self.delegate respondsToSelector:@selector(autolabel:userHandleString:range:)]) {
                    [self.delegate autolabel:self userHandleString:touchedSubstring range:range];
                }
                break;
            case LAutoTypeHashTag:
                if ([self.delegate respondsToSelector:@selector(autolabel:hashTagString:range:)]) {
                    [self.delegate autolabel:self hashTagString:touchedSubstring range:range];
                }
                break;
            case LAutoTypeURL:
                if ([self.delegate respondsToSelector:@selector(autolabel:urlTagString:range:)]) {
                    [self.delegate autolabel:self urlTagString:touchedSubstring range:range];
                }
                break;
                
            default:
                break;
        }
        
    }else{
        [super touchesBegan:touches withEvent:event];
    }
    
    self.selectedRange = NSMakeRange(0, 0);
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesCancelled:touches withEvent:event];
    self.selectedRange = NSMakeRange(0, 0);
}
@end
