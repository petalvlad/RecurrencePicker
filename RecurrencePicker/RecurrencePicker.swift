//
//  RecurrencePicker.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import UIKit
import EventKit
import RRuleSwift

public class RecurrencePicker: UITableViewController {
    public var language: RecurrencePickerLanguage = .English {
        didSet {
            InternationalControl.sharedControl.language = language
        }
    }
    public var delegate: RecurrencePickerDelegate?
    public var tintColor = UIColor.blueColor()
    public var calendar = NSCalendar.currentCalendar()
    public var occurrenceDate = NSDate()

    private var recurrenceRule: RecurrenceRule?
    private var selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)

    // MARK: - Initialization
    public convenience init(recurrenceRule: RecurrenceRule?) {
        self.init(style: .Grouped)
        self.recurrenceRule = recurrenceRule
    }

    // MARK: - Life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }

    public override func didMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            // navigation is popped
            delegate?.recurrencePicker(self, didPickRecurrence: recurrenceRule)
        }
    }
}

extension RecurrencePicker {
    // MARK: - Table view data source and delegate
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Constant.basicRecurrenceStrings().count
        } else {
            return 1
        }
    }

    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Constant.defaultRowHeight
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(CellID.basicRecurrenceCell)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: CellID.basicRecurrenceCell)
        }

        if indexPath.section == 0 {
            cell?.accessoryType = .None
            cell?.textLabel?.text = Constant.basicRecurrenceStrings()[indexPath.row]
        } else {
            cell?.accessoryType = .DisclosureIndicator
            cell?.textLabel?.text = LocalizedString(key: "TBRPPresetRepeatController.textLabel.custom")
        }

        let checkmark =  UIImage(named: "checkmark", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)
        cell?.imageView?.image = checkmark?.imageWithRenderingMode(.AlwaysTemplate)

        if indexPath == selectedIndexPath {
            cell?.imageView?.hidden = false
        } else {
            cell?.imageView?.hidden = true
        }
        return cell!
    }

    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let lastSelectedCell = tableView.cellForRowAtIndexPath(selectedIndexPath)
        let currentSelectedCell = tableView.cellForRowAtIndexPath(indexPath)

        lastSelectedCell?.imageView?.hidden = true
        currentSelectedCell?.imageView?.hidden = false

        selectedIndexPath = indexPath

        if indexPath.section == 0 {
            updateRecurrenceRule(withSelectedIndexPath: indexPath)
            updateFooterTitle()
            navigationController?.popViewControllerAnimated(true)
        } else {
            let customRecurrenceViewController = CustomRecurrenceViewController(style: .Grouped)
            customRecurrenceViewController.occurrenceDate = occurrenceDate
            customRecurrenceViewController.tintColor = tintColor
            customRecurrenceViewController.delegate = self

            customRecurrenceViewController.recurrenceRule = recurrenceRule ?? RecurrenceRule.dailyRecurrence()

            navigationController?.pushViewController(customRecurrenceViewController, animated: true)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

extension RecurrencePicker {
    // MARK: - Helper
    private func commonInit() {
        navigationItem.title = LocalizedString(key: "TBRPPresetRepeatController.navigation.title")
        navigationController?.navigationBar.tintColor = tintColor
        tableView.tintColor = tintColor
        updateSelectedIndexPath(withRule: recurrenceRule)
    }

    private func updateSelectedIndexPath(withRule recurrenceRule: RecurrenceRule?) {
        guard let recurrenceRule = recurrenceRule else {
            selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            return
        }
        if recurrenceRule.isDailyRecurrence() {
            selectedIndexPath = NSIndexPath(forRow: 1, inSection: 0)
        } else if recurrenceRule.isWeeklyRecurrence(occurrenceDate: occurrenceDate) {
            selectedIndexPath = NSIndexPath(forRow: 2, inSection: 0)
        } else if recurrenceRule.isBiWeeklyRecurrence(occurrenceDate: occurrenceDate) {
            selectedIndexPath = NSIndexPath(forRow: 3, inSection: 0)
        } else if recurrenceRule.isMonthlyRecurrence(occurrenceDate: occurrenceDate) {
            selectedIndexPath = NSIndexPath(forRow: 4, inSection: 0)
        } else if recurrenceRule.isYearlyRecurrence(occurrenceDate: occurrenceDate) {
            selectedIndexPath = NSIndexPath(forRow: 5, inSection: 0)
        } else if recurrenceRule.isWeekdayRecurrence() {
            selectedIndexPath = NSIndexPath(forRow: 6, inSection: 0)
        } else {
            selectedIndexPath = NSIndexPath(forRow: 0, inSection: 1)
        }
    }

    private func updateRecurrenceRule(withSelectedIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            return
        }

        switch indexPath.row {
        case 0:
            recurrenceRule = nil
        case 1:
            recurrenceRule = RecurrenceRule.dailyRecurrence()
        case 2:
            let occurrenceDateComponents = calendar.components([.Weekday], fromDate: occurrenceDate)
            let weekday = EKWeekday(rawValue: occurrenceDateComponents.weekday)!
            recurrenceRule = RecurrenceRule.weeklyRecurrence(weekday: weekday)
        case 3:
            let occurrenceDateComponents = calendar.components([.Weekday], fromDate: occurrenceDate)
            let weekday = EKWeekday(rawValue: occurrenceDateComponents.weekday)!
            recurrenceRule = RecurrenceRule.biWeeklyRecurrence(weekday: weekday)
        case 4:
            let occurrenceDateComponents = calendar.components([.Day], fromDate: occurrenceDate)
            let monthday = occurrenceDateComponents.day
            recurrenceRule = RecurrenceRule.monthlyRecurrence(monthday: monthday)
        case 5:
            let occurrenceDateComponents = calendar.components([.Month], fromDate: occurrenceDate)
            let month = occurrenceDateComponents.month
            recurrenceRule = RecurrenceRule.yearlyRecurrence(month: month)
        case 6:
            recurrenceRule = RecurrenceRule.weekdayRecurrence()
        default:
            break
        }
    }

    private func updateFooterTitle() {
        let footerTitle: String? = {
            guard let recurrenceRule = recurrenceRule else {
                return nil
            }
            guard selectedIndexPath.section == 1 else {
                return nil
            }
            return recurrenceRule.toText(occurrenceDate: occurrenceDate)
        }()
        let footerView = tableView.footerViewForSection(1)

        tableView.beginUpdates()
        footerView?.textLabel?.text = footerTitle
        tableView.endUpdates()
        footerView?.setNeedsLayout()
    }
}

extension RecurrencePicker: CustomRecurrenceViewControllerDelegate {
    func customRecurrenceViewController(controller: CustomRecurrenceViewController, didPickRecurrence recurrenceRule: RecurrenceRule) {

    }
}