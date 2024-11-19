#import "YPWebController.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WebKit.h>

typedef enum{
    loadWebURLString = 0,
    loadWebHTMLString,
    POSTWebURLString,
}DGWebLoadType;

static void *WkwebBrowserContext = &WkwebBrowserContext;

@interface YPWebController ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler,UINavigationControllerDelegate,UINavigationBarDelegate>

@property (nonatomic, strong) WKWebView *wkWebView;

@property (nonatomic,strong) UIProgressView *progressView;

@property(nonatomic,assign) BOOL needLoadJSPOST;

@property(nonatomic,assign) DGWebLoadType loadType;

@property (nonatomic, copy) NSString *URLString;

@property (nonatomic, copy) NSString *postData;

@property (nonatomic)NSMutableArray* snapShotsArray;

@property (nonatomic)UIBarButtonItem* customBackBarItem;


@end

@implementation YPWebController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self webViewloadURLType];

    [self.view addSubview:self.wkWebView];

    [self.view addSubview:self.progressView];

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (_isNavHidden == YES) {
        self.navigationController.navigationBarHidden = YES;

        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];

        statusBarView.backgroundColor=[UIColor whiteColor];
 
        [self.view addSubview:statusBarView];
    }else{
        self.navigationController.navigationBarHidden = NO;
    }
}


- (void)roadLoadClicked{
    [self.wkWebView reload];
}

-(void)customBackItemClicked{
    if (self.wkWebView.goBack) {
        [self.wkWebView goBack];
    }
}



- (void)webViewloadURLType{
    switch (self.loadType) {
        case loadWebURLString:{
        
            NSURLRequest * Request_zsj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
        
            [self.wkWebView loadRequest:Request_zsj];
            break;
        }
        case loadWebHTMLString:{
            [self loadHostPathURL:self.URLString];
            break;
        }
        case POSTWebURLString:{
         
            self.needLoadJSPOST = YES;
       
            [self loadHostPathURL:@"WKJSPOST"];
            break;
        }
    }
}

- (void)loadHostPathURL:(NSString *)url{

    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"html"];

    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    [self.wkWebView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
}


- (void)postRequestWithJS {

    NSString *jscript = [NSString stringWithFormat:@"post('%@',{%@});", self.URLString, self.postData];

    [self.wkWebView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
    }];
}


- (void)beiginToLoadUrl:(NSString *)string {
    self.URLString = string;
    self.loadType = loadWebURLString;
}

- (void)loadWebHTMLSring:(NSString *)string{
    self.URLString = string;
    self.loadType = loadWebHTMLString;
}

- (void)POSTWebURLSring:(NSString *)string postData:(NSString *)postData{
    self.URLString = string;
    self.postData = postData;
    self.loadType = POSTWebURLString;
}

-(void)updateNavigationItems{
    if (self.wkWebView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;

        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.customBackBarItem] animated:NO];
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[]];
    }
}

-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request{
 
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapShotsArray lastObject] objectForKey:@"request"];

    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
     
        return;
    }

    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    UIView* currentSnapShotView = [self.wkWebView snapshotViewAfterScreenUpdates:YES];
    [self.snapShotsArray addObject:
     @{@"request":request,@"snapShotView":currentSnapShotView}];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
  
    if (self.needLoadJSPOST) {
   
        [self postRequestWithJS];

        self.needLoadJSPOST = NO;
    }

    self.title = self.wkWebView.title;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
   
    self.progressView.hidden = NO;
}

-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}

-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    
    switch (navigationAction.navigationType) {
        case WKNavigationTypeLinkActivated: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        case WKNavigationTypeFormSubmitted: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        case WKNavigationTypeBackForward: {
            break;
        }
        case WKNavigationTypeReload: {
            break;
        }
        case WKNavigationTypeFormResubmitted: {
            break;
        }
        case WKNavigationTypeOther: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        default: {
            break;
        }
    }
    [self updateNavigationItems];
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"timeout");
}


-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
}

-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    
}

-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tips" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tips" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}


-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
  
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{


}



- (WKWebView *)wkWebView{
    if (!_wkWebView) {
 
        WKWebViewConfiguration * Configuration = [[WKWebViewConfiguration alloc]init];

        Configuration.allowsAirPlayForMediaPlayback = YES;

        Configuration.allowsInlineMediaPlayback = YES;

        Configuration.selectionGranularity = YES;

        Configuration.processPool = [[WKProcessPool alloc] init];
  
        WKUserContentController * UserContentController = [[WKUserContentController alloc]init];

        Configuration.suppressesIncrementalRendering = YES;

        Configuration.userContentController = UserContentController;
        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:Configuration];
        _wkWebView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0];

        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;

        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:WkwebBrowserContext];

        _wkWebView.allowsBackForwardNavigationGestures = YES;

        [_wkWebView sizeToFit];
    }
    return _wkWebView;
}

-(UIBarButtonItem*)customBackBarItem{
    if (!_customBackBarItem) {
        
        UIButton* backButton = [[UIButton alloc] init];
        [backButton setTitle:@"Back" forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [backButton sizeToFit];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        CGFloat statusHeight = [self getStatusBarHeight];
        CGFloat navHeight = statusHeight + 44;
        if (_isNavHidden == YES) {
            _progressView.frame = CGRectMake(0, statusHeight, self.view.bounds.size.width, 3);
        }else{
            _progressView.frame = CGRectMake(0, navHeight, self.view.bounds.size.width, 3);
        }

        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [[UIColor blueColor] colorWithAlphaComponent:0.68];
    }
    return _progressView;
}

- (CGFloat)getStatusBarHeight {
    CGFloat barHeight = 0;

    // iOS 13 and above uses the statusBarManager associated with the windowScene
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;
        
        // If statusBarManager is available, get its status bar frame height
        if (statusBarManager != nil) {
            barHeight = statusBarManager.statusBarFrame.size.height;
        } else {
            // Fallback if statusBarManager is unavailable
            barHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        }
    } else {
        // For iOS 12 and below, directly use UIApplication's statusBarFrame
        barHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    
    // Set a minimum height based on device type (iPhone X or other)
    if (barHeight < 20.0) {
        if ([self isIphoneX]) {
            barHeight = 44.0; // iPhone X and later have a taller status bar
        } else {
            barHeight = 20.0; // Standard status bar height for other iPhones
        }
    }
    return barHeight;
}

- (BOOL)isIphoneX {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    // iPhone X and later models have a height of 812 points or more in portrait mode
    if (width >= 375.0f && height >= 812.0f && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return YES;
    }
    return NO;
}

-(NSMutableArray*)snapShotsArray{
    if (!_snapShotsArray) {
        _snapShotsArray = [NSMutableArray array];
    }
    return _snapShotsArray;
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
}


-(void)dealloc{
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
}

@end
