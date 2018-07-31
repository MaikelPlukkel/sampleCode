//
//  ScrollableInformationPopupTests.swift
//  AnderzorgTests
//
//  Created by Maikel Plukkel on 28/05/2018.
//  Copyright © 2018 Menzis. All rights reserved.
//

import XCTest
@testable import Anderzorg
class ScrollableInformationPopupTests: XCTestCase {
    var scrollableInformationPopup: ScrollableInformationPopup!

    override func setUp() {
        super.setUp()

        scrollableInformationPopup = ScrollableInformationPopup()
        let storyboard = UIStoryboard(name: "ScrollableInformationPopup", bundle: nil)
        if let vc: ScrollableInformationPopup = storyboard.instantiateViewController(withIdentifier: "ScrollableInformationPopup") as? ScrollableInformationPopup {
            scrollableInformationPopup = vc
            _ = scrollableInformationPopup.view
        }
    }

    override func tearDown() {
        scrollableInformationPopup = nil
        super.tearDown()
    }

    func testContentSizeIsCorrect() {
        // arrange
        var contentSizeWidth: CGFloat = 0
        var contentSizeAllSubViews: CGFloat = 0

        // act
        for enumCase in Array(PopupType.cases()) {
            scrollableInformationPopup.popupType = enumCase
            scrollableInformationPopup.setupView()

           contentSizeWidth += scrollableInformationPopup.scrollView.contentSize.width
            scrollableInformationPopup.pages.removeAll()
        }

        contentSizeAllSubViews = scrollableInformationPopup.popupView.frame.width * CGFloat(scrollableInformationPopup.scrollView.subviews.count)

        // assert
        XCTAssertEqual(contentSizeWidth, contentSizeAllSubViews, "numberOfPages and scrollviews are not equal")
    }
}
