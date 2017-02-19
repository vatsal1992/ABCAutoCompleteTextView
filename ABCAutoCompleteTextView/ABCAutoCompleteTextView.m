//
//  ABCAutoCompleteTextView.m
//  ABCAutoCompleteTextView
//
//  Created by Adam Cooper on 10/16/15.
//  Copyright © 2015 Adam Cooper. All rights reserved.
//

#import "ABCAutoCompleteTextView.h"

@interface ABCAutoCompleteTextView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *matchingSearchResults;
@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

@implementation ABCAutoCompleteTextView {
    int _currentWordIndex;
}


CGFloat const UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION = 0.25;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if __has_feature(objc_arc)
#else
    [_placeHolderLabel release]; _placeHolderLabel = nil;
    [_placeholderColor release]; _placeholderColor = nil;
    [_placeholder release]; _placeholder = nil;
    [super dealloc];
#endif
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) )
    {
        [self initialize];
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
    
}

- (void)initialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    
    [self setInputAccessoryView:self.tableView];
}

#pragma mark - Methods

- (void)textChanged:(NSNotification *)notification {
    if([[self placeholder] length] == 0)
    {
        return;
    }
    
    [UIView animateWithDuration:UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION animations:^{
        if([[self text] length] == 0)
        {
            [[self viewWithTag:999] setAlpha:1];
        }
        else
        {
            [[self viewWithTag:999] setAlpha:0];
        }
    }];
    
    [self setNeedsDisplay];
    
    NSRange selectedRange = self.selectedRange;
    
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *start = [self positionFromPosition:beginning offset:selectedRange.location];
    UITextPosition *end = [self positionFromPosition:start offset:selectedRange.length];
    
    UITextRange* textRange = [self.tokenizer rangeEnclosingPosition:end withGranularity:UITextGranularityWord inDirection:UITextLayoutDirectionLeft];
    
    NSString *wordTyped = [self textInRange:textRange];
    
    NSArray *wordsInSentence = [self.text componentsSeparatedByString:@" "];
    
    
    int indexInSavedArray = 0;
    
    for (NSString *string in wordsInSentence) {
        
        NSRange textRange = [self.text rangeOfString:string];
        
        if (selectedRange.location >= textRange.location && selectedRange.location <= (textRange.location + textRange.length) ) {
            NSLog(@"STRING: %@", string);
            
            if ([string hasPrefix:@"@"]) {
                NSLog(@"USER: %@", wordTyped);
                [self refreshSearchResultsWithUsername:string];
                _currentWordIndex = indexInSavedArray;
            } else if ([string hasPrefix:@"#"]) {
                NSLog(@"Hashtag: %@", wordTyped);
                [self refreshSearchResultsWithHashtag:string];
                _currentWordIndex = indexInSavedArray;
            } else {
                self.matchingSearchResults = [NSMutableArray array];
                [self.tableView reloadData];
            }
        }
        indexInSavedArray++;
    }
}

-(void)refreshSearchResultsWithHashtag: (NSString *)hashtag {
    
    if ([hashtag hasPrefix:@"#"]) {
        hashtag = [hashtag substringFromIndex:1];
    }
    
    NSArray *array = nil;
    
    NSMutableArray *formattedResults = [NSMutableArray array];
    
    if (hashtag.length > 0) {
        array = [self.hashtagsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", hashtag]];
    }
    
    for (NSString *hashtag in array) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:hashtag forKey:@"text"];
        [dictionary setObject:@"hashtag" forKey:@"type"];
        [formattedResults addObject:dictionary];
    }
    
    self.matchingSearchResults = formattedResults;
    [self.tableView reloadData];
    
}

-(void)refreshSearchResultsWithUsername: (NSString *)username {
    
    if ([username hasPrefix:@"@"]) {
        username = [username substringFromIndex:1];
    }
    
    NSArray *array = nil;
    NSMutableArray *formattedResults = [NSMutableArray array];
    
    if (username.length > 0) {
        array = [self.usernamesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", username]];
    }
    
    for (NSString *username in array) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:username forKey:@"text"];
        [dictionary setObject:@"username" forKey:@"type"];
        [formattedResults addObject:dictionary];
    }
    
    self.matchingSearchResults = formattedResults;
    [self.tableView reloadData];
}

#pragma mark - UITableView Delegate Methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *chosenDictionary = [self.matchingSearchResults objectAtIndex:indexPath.row];
    NSString *chosenWord = [chosenDictionary objectForKey:@"text"];
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self.text componentsSeparatedByString:@" "]];
    
    NSString *indexWord = [array objectAtIndex:_currentWordIndex];
    
    
    if ([indexWord hasPrefix:@"@"]) {
        
        [array replaceObjectAtIndex:_currentWordIndex withObject:[NSString stringWithFormat:@"@%@ ",chosenWord]];
        
    } else if ([indexWord hasPrefix:@"#"]) {
        
        [array replaceObjectAtIndex:_currentWordIndex withObject:[NSString stringWithFormat:@"#%@ ",chosenWord]];
    }
    
    NSString *totalString = [array componentsJoinedByString:@" "];
    [self setText:totalString];
    self.matchingSearchResults = nil;
    [self.tableView reloadData];
}


#pragma mark - UITableView Datasource Methods

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.matchingSearchResults.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *chosenDictionary = [self.matchingSearchResults objectAtIndex:indexPath.row];
    NSString *word = [chosenDictionary objectForKey:@"text"];
    NSString *type = [chosenDictionary objectForKey:@"type"];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    if ([type isEqualToString:@"hashtag"]) {
        word = [NSString stringWithFormat:@"#%@",word];
    } else {
        word = [NSString stringWithFormat:@"@%@",word];
    }
    
    [cell.textLabel setText:word];
    cell.transform = CGAffineTransformMakeRotation(M_PI);
    [cell setBackgroundColor:[UIColor whiteColor]];
    
    return cell;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged:nil];
}

- (void)drawRect:(CGRect)rect
{
    if( [[self placeholder] length] > 0 )
    {
        if (_placeHolderLabel == nil )
        {
            _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,8,self.bounds.size.width - 16,0)];
            _placeHolderLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _placeHolderLabel.numberOfLines = 0;
            _placeHolderLabel.font = self.font;
            _placeHolderLabel.backgroundColor = [UIColor clearColor];
            _placeHolderLabel.textColor = self.placeholderColor;
            _placeHolderLabel.alpha = 0;
            _placeHolderLabel.tag = 999;
            [self addSubview:_placeHolderLabel];
        }
        
        _placeHolderLabel.text = self.placeholder;
        [_placeHolderLabel sizeToFit];
        [self sendSubviewToBack:_placeHolderLabel];
    }
    
    if( [[self text] length] == 0 && [[self placeholder] length] > 0 )
    {
        [[self viewWithTag:999] setAlpha:1];
    }
    
    [super drawRect:rect];
}

#pragma mark - Properties

-(NSMutableArray *)matchingSearchResults {
    if (!_matchingSearchResults) {
        _matchingSearchResults = [NSMutableArray array];
    }
    return _matchingSearchResults;
}

-(UITableView *)tableView {
    if (!_tableView) {
        _tableView= [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 88) style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setTransform:CGAffineTransformMakeRotation(-M_PI)];
        [_tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
        [_tableView setBackgroundColor:[UIColor clearColor]];
        [_tableView flashScrollIndicators];
    }
    return _tableView;
}

@end
