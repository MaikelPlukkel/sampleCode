import Foundation

@objc enum PopupType: Int, EnumCollection {
    case login = 0
    case declaration
    case loginMessage
}

protocol ScrollableInformationPopupDelegate: class {
    func didDismissPopup()
}

class ScrollableInformationPopup: BaseViewController {
    
    @IBOutlet weak var popupViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIButton!
    
    @objc var popupType: PopupType = .login
    @objc var message: String = ""
    var pages: [PopupView] = []
    weak var delegate: ScrollableInformationPopupDelegate?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupView()
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func setupView() {
        switch popupType {
        case .login:
            pageControl.numberOfPages = 4
            setPages()
            
            pages[0].title.text = NSLocalizedString("login_popup_loginDigid_title", comment: "")
            pages[0].text.text = NSLocalizedString("login_popup_loginDigid_message", comment: "")
            pages[0].headerView.image = UIImage(named: "loginPopup1")
            
            pages[1].title.text = NSLocalizedString("login_popup_digidApp_title", comment: "")
            pages[1].text.text = NSLocalizedString("login_popup_digidApp_message", comment: "")
            pages[1].headerView.image  = UIImage(named: "loginPopup1")
            
            pages[2].title.text = NSLocalizedString("login_popup_loginOptions_title", comment: "")
            pages[2].text.text = NSLocalizedString("login_popup_loginOptions_message", comment: "")
            pages[2].headerView.image  = UIImage(named: "loginPopup3")
            
            pages[3].title.text = NSLocalizedString("login_popup_notYetCustomer_title", comment: "")
            pages[3].text.text = NSLocalizedString("login_popup_notYetCustomer_message", comment: "")
            pages[3].headerView.image  = UIImage(named: "loginPopup2")
            
        case .declaration:
            pageControl.numberOfPages = 2
            setPages()
            
            pages[0].title.text = NSLocalizedString("login_popup_pickInsured_title", comment: "")
            pages[0].text.text = NSLocalizedString("login_popup_pickInsured_message", comment: "")
            pages[0].headerView.image = UIImage(named: "declarationPopup1")
            
            pages[1].title.text = NSLocalizedString("login_popup_sendPDF_title", comment: "")
            pages[1].text.text = NSLocalizedString("login_popup_sendPDF_message", comment: "")
            pages[1].headerView.image  = UIImage(named: "declarationPopup2")
        case .loginMessage:
            pageControl.numberOfPages = 1
            setPages()
            
            pages[0].title.text = NSLocalizedString("login_popup_systemMessage_title", comment: "")
            pages[0].text.text = message
            pages[0].headerView.image = nil
            
            setHeightWithoutImage(pages: pages)
            
            pages[0].headerViewHeightConstraint = pages[0].headerViewHeightConstraint.setMultiplier(multiplier: 0.1)
        }
        
        for (index, page) in pages.enumerated() {
            //set frames
            // first page is width of popupview
            if index == 0 {
                page.frame = CGRect(x: 0, y: 0, width: popupView.frame.width, height: scrollView.frame.height)
                //other pages are width of scrollview times the index
            } else {
                page.frame = CGRect(x: scrollView.frame.width * CGFloat(index), y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
            }
            
            // Add subviews
            if page.title.text! != "Label" {
                scrollView.addSubview(page)
            }
        }
        
        // Set contentsize
        let contentsize = (popupView.frame.width * CGFloat(pageControl.numberOfPages))
        scrollView?.contentSize = CGSize(width: contentsize, height: (scrollView?.contentSize.height)!)
    }
    
    func setPages() {
        for _ in 1...pageControl.numberOfPages {
            if let page = Bundle.main.loadNibNamed("PopupView", owner: self, options: nil)?.first as? PopupView {
                pages.append(page)
            }
        }
        if pageControl.numberOfPages == 1 {
            onePagePopUp()
        }
    }
    
    func onePagePopUp() {
        skipButton.setImage(nil, for: .normal)
        skipButton.setTitle(NSLocalizedString("misc_close", comment: ""), for: .normal)
    }
    
    func setHeightWithoutImage(pages: [PopupView]) {
        let sizeThatFitsTextView = pages[0].text.sizeThatFits(CGSize(width: pages[0].text.frame.size.width, height: CGFloat(MAXFLOAT)))
        let heightOfText = sizeThatFitsTextView.height
        let multiplier = (heightOfText / view.frame.height) + 0.2
        popupViewHeightConstraint = popupViewHeightConstraint.setMultiplier(multiplier: multiplier)
    }
    
    @IBAction func pageControlChangedValue(_ sender: UIPageControl) {
        scrollView.goToPage(page: sender.currentPage)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let delegate = delegate {
            delegate.didDismissPopup()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleBehaviourOfButtonOnPageChange() {
        if scrollView.isOnLastPage() {
            skipButton.finalState()
        } else {
            skipButton.continueState()
        }
    }
    
    @IBAction func skipButtonTouched(_ sender: UIButton) {
        if scrollView.isOnLastPage() {
            if let delegate = delegate {
                delegate.didDismissPopup()
            }
            self.dismiss(animated: true, completion: nil)
        } else {
            scrollView.goToNextPage()
        }
    }
}

extension ScrollableInformationPopup: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = scrollView.getCurrentPage()
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleBehaviourOfButtonOnPageChange()
        pageControl.currentPage = scrollView.getCurrentPage()
    }
}

private extension UIButton {
    func finalState() {
        setImage(nil, for: .normal)
        setTitle(NSLocalizedString("misc_close", comment: ""), for: .normal)
    }
    
    func continueState() {
        setTitle("", for: .normal)
        setImage(UIImage(named: "forward"), for: .normal)
    }
}

private extension UIScrollView {
    func goToPage(page: Int) {
        let pageSize = frame.width
        let offset = pageSize * CGFloat(page)
        setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }
    
    func getPages() -> Int {
        return Int(contentSize.width / frame.width)
        
    }
    
    func getCurrentPage() -> Int {
        return Int(contentOffset.x / frame.size.width)
    }
    
    func isOnLastPage() -> Bool {
        return (getCurrentPage() + 1 == getPages())
    }
    
    func goToNextPage() {
        if !isOnLastPage() {
            goToPage(page: getCurrentPage() + 1)
        }
    }
}
