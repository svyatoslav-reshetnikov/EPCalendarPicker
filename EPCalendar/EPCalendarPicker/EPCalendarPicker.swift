//
//  EPCalendarPicker.swift
//  EPCalendar
//
//  Created by Prabaharan Elangovan on 02/11/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

@objc public protocol EPCalendarPickerDelegate{
    @objc optional func epCalendarPicker(_: EPCalendarPicker, didCancel error : NSError)
    @objc optional func epCalendarPicker(_: EPCalendarPicker, didSelectDate date : Date)
    @objc optional func epCalendarPicker(_: EPCalendarPicker, didSelectMultipleDate dates : [Date])
}

public class EPCalendarPicker: UICollectionViewController {

    public var calendarDelegate : EPCalendarPickerDelegate?
    public var multiSelectEnabled: Bool
    public var showsTodaysButton: Bool = true
    fileprivate var arrSelectedDates = [Date]()
    public var tintColor: UIColor
    
    public var dayDisabledTintColor: UIColor
    public var weekdayTintColor: UIColor
    public var weekendTintColor: UIColor
    public var todayTintColor: UIColor
    public var dateSelectionColor: UIColor
    public var monthTitleColor: UIColor
    
    // new options
    public var startDate: Date?
    public var endDate: Date?
    public var hightlightsToday: Bool = true
    public var hideDaysFromOtherMonth: Bool = false
    public var barTintColor: UIColor
    
    public var backgroundImage: UIImage?
    public var backgroundColor: UIColor?
    
    public var datesCount: Int?
    
    public var doneTitle: String?
    public var cancelTitle: String?
    
    fileprivate(set) public var startYear: Int
    fileprivate(set) public var endYear: Int
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // setup Navigationbar
        navigationController?.navigationBar.tintColor = tintColor
        navigationController?.navigationBar.barTintColor = barTintColor
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: tintColor]

        // setup collectionview
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.clear
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.showsVerticalScrollIndicator = false

        // Register cell classes
        collectionView!.register(UINib(nibName: "EPCalendarCell1", bundle: Bundle(for: EPCalendarPicker.self )), forCellWithReuseIdentifier: reuseIdentifier)
        collectionView!.register(UINib(nibName: "EPCalendarHeaderView", bundle: Bundle(for: EPCalendarPicker.self )), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        
        inititlizeBarButtons()
        
        DispatchQueue.main.async {
            self.scrollToToday()
        }
        
        if backgroundImage != nil {
            collectionView!.backgroundView =  UIImageView(image: backgroundImage)
        } else if backgroundColor != nil {
            collectionView?.backgroundColor = backgroundColor
        } else {
            collectionView?.backgroundColor = UIColor.white
        }
    }

    
    func inititlizeBarButtons(){
        

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(EPCalendarPicker.onTouchCancelButton))
        if let cancelTitle = cancelTitle {
            cancelButton.title = cancelTitle
        }
        self.navigationItem.leftBarButtonItem = cancelButton

        var arrayBarButtons  = [UIBarButtonItem]()
        
        if multiSelectEnabled {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(EPCalendarPicker.onTouchDoneButton))
            if let doneTitle = doneTitle {
                cancelButton.title = doneTitle
            }
            arrayBarButtons.append(doneButton)
        }
        
        if showsTodaysButton {
            let todayButton = UIBarButtonItem(title: "Today", style: .plain, target: self, action:#selector(EPCalendarPicker.onTouchTodayButton))
            arrayBarButtons.append(todayButton)
            todayButton.tintColor = todayTintColor
        }
        
        self.navigationItem.rightBarButtonItems = arrayBarButtons
        
    }
    

    public convenience init(){
        self.init(startYear: EPDefaults.startYear, endYear: EPDefaults.endYear, multiSelection: EPDefaults.multiSelection, selectedDates: nil);
    }
    
    public convenience init(startYear: Int, endYear: Int) {
        self.init(startYear:startYear, endYear:endYear, multiSelection: EPDefaults.multiSelection, selectedDates: nil)
    }
    
    public convenience init(multiSelection: Bool) {
        self.init(startYear: EPDefaults.startYear, endYear: EPDefaults.endYear, multiSelection: multiSelection, selectedDates: nil)
    }
    
    public convenience init(startYear: Int, endYear: Int, multiSelection: Bool) {
        self.init(startYear: EPDefaults.startYear, endYear: EPDefaults.endYear, multiSelection: multiSelection, selectedDates: nil)
    }
    
    public init(startYear: Int, endYear: Int, multiSelection: Bool, selectedDates: [Date]?) {
        
        self.startYear = startYear
        self.endYear = endYear
        
        self.multiSelectEnabled = multiSelection
        
        //Text color initializations
        self.tintColor = EPDefaults.tintColor
        self.barTintColor = EPDefaults.barTintColor
        self.dayDisabledTintColor = EPDefaults.dayDisabledTintColor
        self.weekdayTintColor = EPDefaults.weekdayTintColor
        self.weekendTintColor = EPDefaults.weekendTintColor
        self.dateSelectionColor = EPDefaults.dateSelectionColor
        self.monthTitleColor = EPDefaults.monthTitleColor
        self.todayTintColor = EPDefaults.todayTintColor

        //Layout creation
        let layout = UICollectionViewFlowLayout()
        //layout.sectionHeadersPinToVisibleBounds = true  // If you want make a floating header enable this property(Avaialble after iOS9)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        layout.headerReferenceSize = EPDefaults.headerSize
        if let _ = selectedDates  {
            self.arrSelectedDates.append(contentsOf: selectedDates!)
        }
        super.init(collectionViewLayout: layout)
    }
    

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UICollectionViewDataSource
    
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if startYear > endYear {
            return 0
        }
        
        let numberOfMonths = 12 * (endYear - startYear) + 12
        return numberOfMonths
    }


    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let startDate = Date(year: startYear, month: 1, day: 1)
        let firstDayOfMonth = startDate.dateByAddingMonths(section)
        let addingPrefixDaysWithMonthDyas = ( firstDayOfMonth.numberOfDaysInMonth() + firstDayOfMonth.weekday() - Calendar.current.firstWeekday )
        let addingSuffixDays = addingPrefixDaysWithMonthDyas%7
        var totalNumber  = addingPrefixDaysWithMonthDyas
        if addingSuffixDays != 0 {
            totalNumber = totalNumber + (7 - addingSuffixDays)
        }
        
        return totalNumber
    }
    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EPCalendarCell1
        
        let calendarStartDate = Date(year:startYear, month: 1, day: 1)
        let firstDayOfThisMonth = calendarStartDate.dateByAddingMonths(indexPath.section)
        let prefixDays = ( firstDayOfThisMonth.weekday() - Calendar.current.firstWeekday)
        
        if indexPath.row >= prefixDays {
            cell.isCellSelectable = true
            let currentDate = firstDayOfThisMonth.dateByAddingDays(indexPath.row-prefixDays)
            let nextMonthFirstDay = firstDayOfThisMonth.dateByAddingDays(firstDayOfThisMonth.numberOfDaysInMonth()-1)
            
            cell.currentDate = currentDate
            cell.lblDay.text = "\(currentDate.day())"
            
            if arrSelectedDates.filter({ $0.isDateSameDay(currentDate)
            }).count > 0 && (firstDayOfThisMonth.month() == currentDate.month()) {

                cell.selectedForLabelColor(dateSelectionColor)
            }
            else{
                cell.deSelectedForLabelColor(weekdayTintColor)
               
                if cell.currentDate.isSaturday() || cell.currentDate.isSunday() {
                    cell.lblDay.textColor = weekendTintColor
                }
                if (currentDate > nextMonthFirstDay) {
                    cell.isCellSelectable = false
                    if hideDaysFromOtherMonth {
                        cell.lblDay.textColor = UIColor.clear
                    } else {
                        cell.lblDay.textColor = self.dayDisabledTintColor
                    }
                }
                if currentDate.isToday() && hightlightsToday {
                    cell.setTodayCellColor(todayTintColor)
                }
               
                if startDate != nil {
                    if Calendar.current.startOfDay(for: cell.currentDate as Date) < NSCalendar.current.startOfDay(for: startDate! as Date) {
                        cell.isCellSelectable = false
                        cell.lblDay.textColor = self.dayDisabledTintColor
                    }
                }
                
                if endDate != nil {
                    if Calendar.current.startOfDay(for: cell.currentDate as Date) > NSCalendar.current.startOfDay(for: endDate! as Date) {
                        cell.isCellSelectable = false
                        cell.lblDay.textColor = self.dayDisabledTintColor
                    }
                }
            }
        }
        else {
            cell.deSelectedForLabelColor(weekdayTintColor)
            cell.isCellSelectable = false
            let previousDay = firstDayOfThisMonth.dateByAddingDays(-( prefixDays - indexPath.row))
            cell.currentDate = previousDay
            cell.lblDay.text = "\(previousDay.day())"
            if hideDaysFromOtherMonth {
                cell.lblDay.textColor = UIColor.clear
            } else {
                cell.lblDay.textColor = self.dayDisabledTintColor
            }
        }
        
        cell.backgroundColor = UIColor.clear
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        
        let rect = UIScreen.main.bounds
        let screenWidth = rect.size.width - 7
        return CGSize(width: screenWidth/7, height: screenWidth/7);
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(5, 0, 5, 0); //top,left,bottom,right
    }
    
    override public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! EPCalendarHeaderView
            
            let startDate = Date(year: startYear, month: 1, day: 1)
            let firstDayOfMonth = startDate.dateByAddingMonths(indexPath.section)
            
            header.lblTitle.text = firstDayOfMonth.monthNameFull()
            header.lblTitle.textColor = monthTitleColor
            header.updateWeekdaysLabelColor(weekdayTintColor)
            header.updateWeekendLabelColor(weekendTintColor)
            header.backgroundColor = UIColor.clear
            
            return header;
        }
        
        return UICollectionReusableView()
    }
    
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! EPCalendarCell1
        if !multiSelectEnabled && cell.isCellSelectable! {
            calendarDelegate?.epCalendarPicker!(self, didSelectDate: cell.currentDate)
            cell.selectedForLabelColor(dateSelectionColor)
            dismiss(animated: true, completion: nil)
            return
        }
        
        if cell.isCellSelectable! {
            
            if arrSelectedDates.filter({ $0.isDateSameDay(cell.currentDate)
            }).count == 0 {
                arrSelectedDates.append(cell.currentDate)
                cell.selectedForLabelColor(dateSelectionColor)
                
                if cell.currentDate.isToday() {
                    cell.setTodayCellColor(dateSelectionColor)
                }
            }
            else {
                arrSelectedDates = arrSelectedDates.filter(){
                    return  !($0.isDateSameDay(cell.currentDate))
                }
                if cell.currentDate.isSaturday() || cell.currentDate.isSunday() {
                    cell.deSelectedForLabelColor(weekendTintColor)
                }
                else {
                    cell.deSelectedForLabelColor(weekdayTintColor)
                }
                if cell.currentDate.isToday() && hightlightsToday{
                    cell.setTodayCellColor(todayTintColor)
                }
            }
        }
        
        if arrSelectedDates.count > datesCount! {
            arrSelectedDates.removeFirst()
            collectionView.reloadData()
        }
    }
    
    //MARK: Button Actions
    
    internal func onTouchCancelButton() {
       //TODO: Create a cancel delegate
        calendarDelegate?.epCalendarPicker!(self, didCancel: NSError(domain: "EPCalendarPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        dismiss(animated: true, completion: nil)
        
    }
    
    internal func onTouchDoneButton() {
        //gathers all the selected dates and pass it to the delegate
        calendarDelegate?.epCalendarPicker!(self, didSelectMultipleDate: arrSelectedDates)
        dismiss(animated: true, completion: nil)
    }

    internal func onTouchTodayButton() {
        scrollToToday()
    }
    
    
    public func scrollToToday () {
        let today = Date()
        scrollToMonthForDate(today)
    }
    
    public func scrollToMonthForDate (_ date: Date) {

        let month = date.month()
        let year = date.year()
        let section = ((year - startYear) * 12) + month
        let indexPath = IndexPath(row:1, section: section-1)
        
        self.collectionView?.scrollToIndexpathByShowingHeader(indexPath)
    }
    
    
}
