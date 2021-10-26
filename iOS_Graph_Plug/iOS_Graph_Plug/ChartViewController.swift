//
//  ViewController.swift
//  iOS_Graph_Plug
//
//  Created by macbook pro on 09/01/19.
//  Copyright © 2019 Omni-Bridge. All rights reserved.
//

import UIKit
import DropDown
import Charts

class ChartViewController: UIViewController {
    
    // MARK:- Variables and Outlets declaration
    
    @IBOutlet weak var segmentController: UISegmentedControl!
    @IBOutlet var btnForFromDate: UIButton!
    @IBOutlet var btnForToDate: UIButton!
    @IBOutlet var btnForDropDownView: UIButton!
    @IBOutlet weak var lblForChartName : UILabel!
    @IBOutlet weak var lblForTableName : UILabel!
    @IBOutlet weak var viewForGraph : UIView!
    @IBOutlet weak var tableViewForChart : UITableView!
    @IBOutlet weak var datePickerView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    lazy var originalRect : CGRect! = {
        return CGRect(x: 0, y: self.view.bounds.height - 295, width: self.view.bounds.width , height: 295)
    }()
    let calenderDropDown = DropDown()
    let filterDropDown = DropDown()
    let headerArrayForTableView = [["Usage"],["Read","Unread"],["Like","Comment"]]
    let objectArrayForTableView = NSMutableArray()
    
    lazy var viewForFilterDropdown : UIView = {
        return UIView(frame: CGRect(x: self.view.bounds.width - 80, y: (UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)), width: 75, height: 1))
    }()
    
    lazy var usageGraphView : LineChartView = {
        return LineChartView(frame: self.viewForGraph.bounds)
    }()
    
    lazy var accomplishGraphView : PieChartView = {
        return PieChartView(frame: self.viewForGraph.bounds)
    }()
    
    lazy var activityGraphView : BarChartView = {
        return BarChartView(frame: self.viewForGraph.bounds)
    }()
    
    var selectedDateIdentifier = ""
    var userRegistrationDate = Date()
    var platformFilterArray = NSArray()
    var selectedPlatformId = ""
    var currentgraphName = GRAPH_NAME.AppUsage
    
    // MARK:- Color code
    let colorForUsageGraphLine = UIColor(red: 83/255, green: 168/255, blue: 226/255, alpha: 1)
    let colorForFillLineUsageGraph = UIColor(red: 203/255, green: 228/255, blue: 246/255, alpha: 1)
    let colorForReadInAccomplishGraph = UIColor(red: 83/255, green: 168/255, blue: 226/255, alpha: 1)
    let colorForUnreadInAccomplishGraph = UIColor(red: 203/255, green: 228/255, blue: 246/255, alpha: 1)
    let colorForLikeInActivityGraph = UIColor(red: 83/255, green: 168/255, blue: 226/255, alpha: 1)
    let colorForCommentInActivityGraph = UIColor(red: 103/255, green: 218/255, blue: 251/255, alpha: 1)
    
    // MARK:- View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentController.addUnderlineForSelectedSegment()
        if self.view.bounds.height == 568{
            self.btnForToDate.titleLabel?.font = UIFont.systemFont(ofSize: 10)
            self.btnForFromDate.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        }
        self.tableViewForChart.tableFooterView = UIView()
        //set Custom date picker property
        datePicker.maximumDate = Date()
        self.datePickerView.isHidden = true
        // Add default usage graph view
        self.addGraphToMainView(segmentIndex: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.callAPIsForPlatforms()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    /// Used to show network alert message
    private func showNetworkUnavailableAlert(){
        self.stopLoader()
        let alertVc = UIAlertController(title: Error_Message.NETWORK_FAILURE_TITLE, message: Error_Message.NETWORK_FAILURE_MESSAGE, preferredStyle: UIAlertController.Style.alert)
        alertVc.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alertVc, animated: true, completion: nil)
    }
    
    /// Used to start activity loader
    private func startLoader(){
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
    }
    
    /// Used to stop activity loader
    private func stopLoader(){
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
    }
    
    /// Used to add Graph based on segment index
    ///
    /// - Parameter segmentIndex: index
    private func addGraphToMainView(segmentIndex : Int){
        self.removeAllViewFromGraphView()
        switch segmentIndex {
        case 0:
            self.createUsageGraphView()
            break
        case 1:
            self.createAccomplishGraphView()
            break
        case 2:
            self.createActivityGraphView()
            break
        default:
            print("Something Went wrong")
        }
    }
    /// Used to remove all view from viewForGraph
    private func removeAllViewFromGraphView(){
        for view in self.viewForGraph.subviews{
            view.removeFromSuperview()
        }
    }
    
    // MARK:- APIs Call methods
    
    /// Used to call Platform data from server
    private func callAPIsForPlatforms(){
        if !General.isConnectedToNetwork(){
            self.showNetworkUnavailableAlert()
            return
        }
        self.startLoader()
        APIs.performGet(requestStr: GRAPH_NAME.PlatformData, query: "userId=\(GRAPH_NAME.UserId)") { (data) in
            if let responseDict = (data as? NSDictionary)?.value(forKey: "data") as? NSDictionary{
                self.userRegistrationDate = Date(timeIntervalSince1970: (Double(responseDict.value(forKey: "registeredDate") as? Double ?? 0) / 1000))
                self.platformFilterArray = responseDict.value(forKey: "platform") as? NSArray ?? NSArray()
                self.selectedPlatformId = "\(((responseDict.value(forKey: "platform") as? NSArray ?? NSArray()).firstObject as? NSDictionary ?? NSDictionary()).value(forKey: "id") as? Int ?? 0)"
                self.setFilterDropDown()
                self.setCalenderDropDown()
            }
        }
    }
    
    
    /// Used to call Graph data from serve
    ///
    /// - Parameters:
    ///   - graphHostName: Graph name
    ///   - platformId: Platform Id
    ///   - strFromDate: Start date
    ///   - strToDate: End date
    private func callGraphDataAPIs(graphHostName : String, platformId : String,strFromDate : String , strToDate: String){
        if !General.isConnectedToNetwork(){
            self.showNetworkUnavailableAlert()
            return
        }
        self.startLoader()
        APIs.performGet(requestStr: graphHostName, query: "UserId=\(GRAPH_NAME.UserId)&StartDate=\(General.formatedDate(date: General.stringToDateConvertor(strDate: strFromDate, formator: General.DEFAULT_DATE_FORMATOR), formatorStr: General.API_DATE_FORMATOR))&EndDate=\(General.formatedDate(date: General.stringToDateConvertor(strDate: strToDate, formator: General.DEFAULT_DATE_FORMATOR), formatorStr: General.API_DATE_FORMATOR))&PlatformId=\(platformId)") { (data) in
            if let dataArr = (data as? NSDictionary)?.value(forKey: "data") as? NSArray{
                self.objectArrayForTableView.removeAllObjects()
                switch self.segmentController.selectedSegmentIndex{
                case 0 : self.setDataToUsageGraphView(data: dataArr)
                self.tableViewForChart.reloadData()
                case 1 : self.setDataToAccomplishgraphView(data: dataArr)
                self.tableViewForChart.reloadData()
                case 2 : self.setDataToActivityGraphView(data: dataArr)
                self.tableViewForChart.reloadData()
                default:
                    print("Something went wrong")
                }
            }
            self.stopLoader()
        }
    }
    
    /// Used to call Graph data from server
    ///
    /// - Parameters:
    ///   - graphHostName: Graph name
    ///   - platformId: Platform Id
    private func callGraphDataAPIs(graphHostName : String, platformId : String){
        if !General.isConnectedToNetwork(){
            self.showNetworkUnavailableAlert()
            return
        }
        self.startLoader()
        APIs.performGet(requestStr: graphHostName, query: "UserId=\(GRAPH_NAME.UserId)&StartDate=\(General.formatedDate(date: General.stringToDateConvertor(strDate: (self.btnForFromDate.titleLabel?.text)!, formator: General.DEFAULT_DATE_FORMATOR), formatorStr: General.API_DATE_FORMATOR))&EndDate=\(General.formatedDate(date: General.stringToDateConvertor(strDate: (self.btnForToDate.titleLabel?.text)!, formator: General.DEFAULT_DATE_FORMATOR), formatorStr: General.API_DATE_FORMATOR))&PlatformId=\(platformId)") { (data) in
            if let dataArr = (data as? NSDictionary)?.value(forKey: "data") as? NSArray{
                self.objectArrayForTableView.removeAllObjects()
                switch self.segmentController.selectedSegmentIndex{
                case 0 : self.setDataToUsageGraphView(data: dataArr)
                self.tableViewForChart.reloadData()
                case 1 : self.setDataToAccomplishgraphView(data: dataArr)
                self.tableViewForChart.reloadData()
                case 2 : self.setDataToActivityGraphView(data: dataArr)
                self.tableViewForChart.reloadData()
                default:
                    print("Something went wrong")
                }
            }
            self.stopLoader()
        }
        
    }
    
    // MARK:- Line Graph
    
    /// Initialize line graph with default property
    private func createUsageGraphView(){
        self.usageGraphView.xAxis.labelPosition = .bottom
        self.usageGraphView.animate(yAxisDuration: 1)
        self.usageGraphView.legend.enabled = false
        self.usageGraphView.chartDescription?.enabled = false
        self.usageGraphView.xAxis.drawGridLinesEnabled = false
        self.usageGraphView.rightAxis.drawLabelsEnabled = false
        self.usageGraphView.rightAxis.enabled = false
        self.usageGraphView.leftAxis.gridLineWidth = 0.1
        self.usageGraphView.leftAxis.axisLineWidth = 0
        
        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        marker.chartView = self.usageGraphView
        
        marker.minimumSize = CGSize(width: 80, height: 60)
        
        self.usageGraphView.rightAxis.axisMinimum = 0
        self.usageGraphView.leftAxis.axisMinimum = 0
        
        //self.usageGraphView.autoScaleMinMaxEnabled = true
        //self.usageGraphView.highestVisibleX = 5
        
        self.usageGraphView.marker = marker
        self.usageGraphView.setNeedsDisplay()
        self.viewForGraph.addSubview(self.usageGraphView)
    }
    
    /// Used to set data to line graph
    ///
    /// - Parameter data: data array
    private func setDataToUsageGraphView(data : NSArray){
        var lineChartEntry = [ChartDataEntry]()
        for i in 0..<data.count{
            let value = ChartDataEntry(x: (Double((data[i] as! NSDictionary).value(forKey: "date") as? Double ?? 0) / 1000), y: (Double((data[i] as! NSDictionary).value(forKey: "usage") as? Double ?? 0) / 60))
            lineChartEntry.append(value)
            objectArrayForTableView.add([(Double((data[i] as! NSDictionary).value(forKey: "date") as? Double ?? 0) / 1000), (Double((data[i] as! NSDictionary).value(forKey: "usage") as? Double ?? 0) / 1)])
        }
        let line = LineChartDataSet(values: lineChartEntry, label: "Number")
        line.mode = .cubicBezier
        line.drawCirclesEnabled = false
        line.drawValuesEnabled = false
        line.drawFilledEnabled = true
        line.lineWidth = 2
        line.setColor(self.colorForUsageGraphLine)
        line.fillColor = self.colorForFillLineUsageGraph
        line.setDrawHighlightIndicators(false)
        let data = LineChartData()
        data.addDataSet(line)
        self.usageGraphView.data = data
        if self.calenderDropDown.selectedItem == "Week"{
            self.usageGraphView.xAxis.valueFormatter = CalenderWeekdayXAxisValueFormator()
        }else{
            self.usageGraphView.xAxis.valueFormatter = CalenderDateXAxisValueFormator()
        }
        self.usageGraphView.leftAxis.valueFormatter = YAxisMinValueFormator()
        self.usageGraphView.contentMode = .center
        self.usageGraphView.setNeedsDisplay()
    }
    
    // MARK:- Pie Chart
    
    /// Initialize Pie graph with default property
    private func createAccomplishGraphView(){
        self.accomplishGraphView.drawHoleEnabled = false
        self.accomplishGraphView.usePercentValuesEnabled = true
        self.accomplishGraphView.chartDescription?.enabled = false
        self.accomplishGraphView.legend.horizontalAlignment = Legend.HorizontalAlignment.center
        self.accomplishGraphView.legend.form = Legend.Form.circle
        self.accomplishGraphView.setNeedsLayout()
        self.viewForGraph.addSubview(self.accomplishGraphView)
    }
    /// Used to set data to pie chart
    ///
    /// - Parameter data: data array
    private func setDataToAccomplishgraphView(data : NSArray){
        var pieChartEntry = [PieChartDataEntry]()
        var readCount = 0
        var unReadCount = 0
        for dataObj in data{
            if let objDict = dataObj as? NSDictionary {
                readCount += objDict.value(forKey: "read") as? Int ?? 0
                unReadCount += objDict.value(forKey: "unread") as? Int ?? 0
                self.objectArrayForTableView.add([(objDict.value(forKey: "date") as? Int ?? 0)/1000, objDict.value(forKey: "read") as? Int ?? 0, objDict.value(forKey: "unread") as? Int ?? 0])
            }
        }
        pieChartEntry.append(PieChartDataEntry(value: Double(readCount), label: "READ"))
        pieChartEntry.append(PieChartDataEntry(value: Double(unReadCount), label: "UNREAD"))
        let set = PieChartDataSet(values: pieChartEntry, label: nil)
        let colors = [self.colorForReadInAccomplishGraph,
                      self.colorForUnreadInAccomplishGraph]
        set.colors = colors
        set.drawValuesEnabled = true
        
        let data = PieChartData(dataSet: set)
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        self.accomplishGraphView.data = data
        self.accomplishGraphView.contentMode = .center
        self.accomplishGraphView.setNeedsLayout()
    }
    
    // MARK:- Group Bar Chart
    
    /// Initialize Bar graph with default property
    private func createActivityGraphView(){
        
        self.activityGraphView.xAxis.centerAxisLabelsEnabled = true
        
        //self.activityGraphView.xAxis.labelCount = 5
        self.activityGraphView.xAxis.spaceMin = 0.5
        self.activityGraphView.xAxis.spaceMax = 0.5
        self.activityGraphView.xAxis.granularityEnabled = false
        self.activityGraphView.xAxis.granularity = 1
        
        self.activityGraphView.leftAxis.axisLineWidth = 0
        self.activityGraphView.leftAxis.gridLineWidth = 0.1
        
        
        self.activityGraphView.legend.form = Legend.Form.circle
        self.activityGraphView.chartDescription?.enabled = false
        self.activityGraphView.legend.horizontalAlignment = Legend.HorizontalAlignment.center
        //self.barChart.dragEnabled = false
        self.activityGraphView.pinchZoomEnabled = false
        self.activityGraphView.doubleTapToZoomEnabled = false
        self.activityGraphView.rightAxis.enabled = false
        self.activityGraphView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        self.activityGraphView.rightAxis.axisMinimum = 0
        self.activityGraphView.leftAxis.axisMinimum = 0
        self.activityGraphView.xAxis.drawGridLinesEnabled = false
        self.activityGraphView.xAxis.drawAxisLineEnabled = false
        self.viewForGraph.addSubview(self.activityGraphView)
    }
    /// Used to set data to bar graph
    ///
    /// - Parameter data: data array
    private func setDataToActivityGraphView(data : NSArray){
        var dataEntryForLikes = [BarChartDataEntry]()
        var dataEntryForComments = [BarChartDataEntry]()
        var xAxisNameArray = [String]()
        for dataObj in data{
            if let objDict = dataObj as? NSDictionary {
                self.objectArrayForTableView.add([(objDict.value(forKey: "date") as? Int ?? 0)/1000, objDict.value(forKey: "like") as? Int ?? 0, objDict.value(forKey: "comment") as? Int ?? 0])
                let dateInSec = ((objDict.value(forKey: "date") as? Int ?? 0) / 1000)
                dataEntryForLikes.append(BarChartDataEntry(x: Double(dateInSec), y: Double(objDict.value(forKey: "like") as? Int ?? 0)))
                dataEntryForComments.append(BarChartDataEntry(x: Double(dateInSec), y: Double(objDict.value(forKey: "comment") as? Int ?? 0)))
                if self.calenderDropDown.selectedItem == "Week"{
                    xAxisNameArray.append(CalenderWeekdayXAxisValueFormator().stringForValue(Double(dateInSec), axis: nil))
                }else{
                    xAxisNameArray.append(CalenderDateXAxisValueFormator().stringForValue(Double(dateInSec), axis: nil))
                }
            }
        }
        let dataSet1 = BarChartDataSet(values: dataEntryForLikes, label: "Likes")
        dataSet1.setColor(self.colorForLikeInActivityGraph)
        let dataSet2 = BarChartDataSet(values: dataEntryForComments, label: "Comments")
        dataSet2.setColor(self.colorForCommentInActivityGraph)
        let dataSet :[BarChartDataSet] = [dataSet1,dataSet2]
        let chartData = BarChartData(dataSets: dataSet)
        
        let groupSpace = 0.4
        let barSpace = 0.00
        let barWidth = 0.3
        // (0.3 + 0.05) * 2 + 0.3 = 1.00 -> interval per "group"
        
        let groupCount = xAxisNameArray.count
        let startYear = 0
        
        chartData.barWidth = barWidth;
        activityGraphView.xAxis.axisMinimum = Double(startYear)
        let calculatedGroupSpace = chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        activityGraphView.xAxis.axisMaximum = Double(startYear) + calculatedGroupSpace * Double(groupCount)
        
        chartData.groupBars(fromX: Double(startYear), groupSpace: groupSpace, barSpace: barSpace)
        activityGraphView.notifyDataSetChanged()
        self.activityGraphView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xAxisNameArray)
        self.activityGraphView.data = chartData
    }
    
    // MARK:- Button Action methods
    
    @IBAction func segmentTapPressed(_ sender: UISegmentedControl) {
        self.hideDatePickerView(view: self.datePickerView, frame: self.originalRect)
        if !General.isConnectedToNetwork(){
            self.showNetworkUnavailableAlert()
            switch self.currentgraphName{
            case GRAPH_NAME.AppUsage :sender.selectedSegmentIndex = 0
            case GRAPH_NAME.Accomplish :sender.selectedSegmentIndex = 1
            case GRAPH_NAME.Activity :sender.selectedSegmentIndex = 2
            default: print("No Graph selected")
            }
            return
        }
        
        sender.changeUnderlinePosition()
        
        self.calenderDropDown.clearSelection()
        self.calenderDropDown.selectRow(at: 0)
        self.btnForDropDownView.setTitle("Week", for: UIControl.State.normal)
        self.objectArrayForTableView.removeAllObjects()
        self.addGraphToMainView(segmentIndex: sender.selectedSegmentIndex)
        self.tableViewForChart.reloadData()
        switch sender.selectedSegmentIndex {
        case 0:
            self.currentgraphName = GRAPH_NAME.AppUsage
            self.lblForChartName.text = "App Usage"
            self.setDateAndTitle(onIndex: 0)
            self.tableViewForChart.reloadData()
        case 1:
            self.currentgraphName = GRAPH_NAME.Accomplish
            self.lblForChartName.text = "Accomplishment"
            self.setDateAndTitle(onIndex: 0)
            self.tableViewForChart.reloadData()
        case 2:
            self.currentgraphName = GRAPH_NAME.Activity
            self.lblForChartName.text = "Activity"
            self.setDateAndTitle(onIndex: 0)
            self.tableViewForChart.reloadData()
        default:
            print("No selection")
        }
    }
    
    @IBAction func showCalenderDropDown(_ sender: Any) {
        self.calenderDropDown.show()
    }
    
    @IBAction func showFilterDropDown(_ sender: Any) {
        self.filterDropDown.show()
    }
    
    @IBAction func toCalenderPressed(_ sender: Any) {
        selectedDateIdentifier = "To"
        self.datePicker.maximumDate = nil
        self.datePicker.date = General.stringToDateConvertor(strDate: (self.btnForToDate.titleLabel?.text)!, formator: General.DEFAULT_DATE_FORMATOR)
        self.datePicker.maximumDate = Date()
        self.datePicker.minimumDate = General.stringToDateConvertor(strDate: (self.btnForFromDate.titleLabel?.text)!, formator: General.DEFAULT_DATE_FORMATOR)
        self.GoUp(view: datePickerView, frame: originalRect)
    }
    
    @IBAction func fromCalenderPressed(_ sender: Any) {
        selectedDateIdentifier = "From"
        self.datePicker.date = General.stringToDateConvertor(strDate: (self.btnForFromDate.titleLabel?.text)!, formator: General.DEFAULT_DATE_FORMATOR)
        self.datePicker.maximumDate = Calendar.current.date(byAdding: .day, value: -1, to: General.stringToDateConvertor(strDate: (self.btnForToDate.titleLabel?.text)!, formator: General.DEFAULT_DATE_FORMATOR))
        self.datePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        self.GoUp(view: datePickerView, frame: originalRect)
    }
    
    // MARK:- Add Dropdown
    
    /// Setting calender dropdown ie. "Week"/"Month"/"Custom"
    func setCalenderDropDown(){
        calenderDropDown.anchorView = self.btnForDropDownView // UIView or UIBarButtonItem
        calenderDropDown.bottomOffset = CGPoint(x: 0, y: self.btnForDropDownView.bounds.height)
        calenderDropDown.dataSource = ["Week","Month","Custom"]
        calenderDropDown.selectRow(0)
        self.setDateAndTitle(onIndex: 0)
        calenderDropDown.selectionAction = { (index: Int, item: String) in
            self.hideDatePickerView(view: self.datePickerView, frame: self.originalRect)
            if !General.isConnectedToNetwork(){
                self.calenderDropDown.clearSelection()
                switch self.btnForDropDownView.titleLabel?.text{
                case "Week": self.calenderDropDown.selectRow(0)
                case "Month": self.calenderDropDown.selectRow(1)
                case "Custom": self.calenderDropDown.selectRow(2)
                default : print("No Selection")
                }
                self.showNetworkUnavailableAlert()
                return
            }
            self.btnForDropDownView.setTitle(item, for: .normal)
            self.addGraphToMainView(segmentIndex: self.segmentController.selectedSegmentIndex)
            self.setDateAndTitle(onIndex: index)
        }
    }
    
    /// Setting platform filter dropdown
    func setFilterDropDown(){
        self.view.addSubview(viewForFilterDropdown)
        filterDropDown.anchorView = viewForFilterDropdown // UIView or UIBarButtonItem
        let platformArr = NSMutableArray()
        for platformObj in self.platformFilterArray{
            platformArr.add((platformObj as! NSDictionary).value(forKey: "name") as? String ?? "")
        }
        filterDropDown.dataSource = platformArr as! [String]
        filterDropDown.selectRow(0)
        filterDropDown.selectionAction = { (index: Int, item: String) in
            guard let platformObjDict = self.platformFilterArray.object(at: index) as? NSDictionary else{return}
            self.hideDatePickerView(view: self.datePickerView, frame: self.originalRect)
            if !General.isConnectedToNetwork(){
                for prevSelectedIndx in 0..<self.platformFilterArray.count{
                    if let ObjDict = self.platformFilterArray.object(at: prevSelectedIndx) as? NSDictionary{
                        if (ObjDict.value(forKey: "id") as? Int ?? 0) == (self.selectedPlatformId as NSString).intValue{
                            self.filterDropDown.clearSelection()
                            self.filterDropDown.selectRow(prevSelectedIndx)
                            break
                        }
                    }
                }
                self.showNetworkUnavailableAlert()
                return
            }
            self.selectedPlatformId = "\(platformObjDict.value(forKey: "id") as? Int ?? 0)"
            self.callGraphDataAPIs(graphHostName: self.currentgraphName, platformId: self.selectedPlatformId)
        }
    }
    
    /// Used to set date based on index
    ///
    /// - Parameter onIndex: index
    func setDateAndTitle(onIndex : Int){
        self.btnForToDate.setTitleColor(UIColor.lightGray, for: .normal)
        self.btnForFromDate.setTitleColor(UIColor.lightGray, for: .normal)
        self.objectArrayForTableView.removeAllObjects()
        self.btnForFromDate.isEnabled = false
        self.btnForToDate.isEnabled = false
        
        self.btnForToDate.layer.borderColor = UIColor.lightGray.cgColor
        self.btnForFromDate.layer.borderColor = UIColor.lightGray.cgColor
        
        switch onIndex {
        case 0: // used to set current date and one week back date
            self.lblForTableName.text = "Weekly Report"
            self.btnForToDate.setTitle(General.formatedDate(date: Date(), formatorStr: "dd/MM/yyyy"), for: .normal)
            self.btnForFromDate.setTitle(General.formatedDate(date:Calendar.current.date(byAdding: .day, value: -6, to: Date())!, formatorStr: "dd/MM/yyyy"), for: .normal)
            
            self.callGraphDataAPIs(graphHostName: self.currentgraphName, platformId: "\(self.selectedPlatformId)", strFromDate: General.formatedDate(date:Calendar.current.date(byAdding: .day, value: -6, to: Date())!, formatorStr: "dd/MM/yyyy"), strToDate: General.formatedDate(date: Date(), formatorStr: "dd/MM/yyyy"))
            
        case 1: // used to set current date and current month start date
            self.lblForTableName.text = "Monthly Report"
            self.btnForToDate.setTitle(General.formatedDate(date: Date(), formatorStr: "dd/MM/yyyy"), for: .normal)
            let dateComponent = Calendar.current.dateComponents([.month,.year], from: Date())
            self.btnForFromDate.setTitle("01/\(dateComponent.month! > 9 ? "\(dateComponent.month!)" : "0\(dateComponent.month!)")/\(dateComponent.year! )", for: .normal)
            
            self.callGraphDataAPIs(graphHostName: self.currentgraphName, platformId: "\(self.selectedPlatformId)", strFromDate: "01/\(dateComponent.month! > 9 ? "\(dateComponent.month!)" : "0\(dateComponent.month!)")/\(dateComponent.year! )", strToDate: General.formatedDate(date: Date(), formatorStr: "dd/MM/yyyy"))
        case 2: // to allow select custom date
            self.lblForTableName.text = "Custom Report"
            self.btnForFromDate.isEnabled = true
            self.btnForToDate.isEnabled = true
            
            self.btnForToDate.layer.borderColor = UIColor.black.cgColor
            self.btnForFromDate.layer.borderColor = UIColor.black.cgColor
            
            self.btnForToDate.setTitleColor(UIColor.black, for: .normal)
            self.btnForFromDate.setTitleColor(UIColor.black, for: .normal)
        default:
            print("No selection")
        }
    }
}

// MARK: - CellForChartTable

/// UITableViewCell
class CellForChartTable: UITableViewCell {
    @IBOutlet weak var lblForDate : UILabel!
    @IBOutlet weak var lblForColumnOne: UILabel!
    @IBOutlet weak var lblForColumnTwo:UILabel!
}

// MARK: - UISegmentedControl

extension UISegmentedControl{
    func removeBorder(){
        let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: self.bounds.size)
        self.setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        self.setBackgroundImage(backgroundImage, for: .selected, barMetrics: .default)
        self.setBackgroundImage(backgroundImage, for: .highlighted, barMetrics: .default)
        
        let deviderImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: CGSize(width: 1.0, height: self.bounds.size.height))
        self.setDividerImage(deviderImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
    }
    
    func addUnderlineForSelectedSegment(){
        removeBorder()
        let underlineWidth: CGFloat = self.bounds.size.width / CGFloat(self.numberOfSegments)
        let underlineHeight: CGFloat = 3.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = self.bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition, y: underLineYPosition, width: underlineWidth, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = UIColor.purple
        underline.tag = 1
        self.addSubview(underline)
    }
    
    func changeUnderlinePosition(){
        guard let underline = self.viewWithTag(1) else {return}
        let underlineFinalXPosition = (self.bounds.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
        UIView.animate(withDuration: 0.1, animations: {
            underline.frame.origin.x = underlineFinalXPosition
        })
    }
}

// MARK: - UIImage

extension UIImage{
    
    class func getColoredRectImageWith(color: CGColor, andSize size: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let graphicsContext = UIGraphicsGetCurrentContext()
        graphicsContext?.setFillColor(color)
        let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        graphicsContext?.fill(rectangle)
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage!
    }
}

// MARK: - UITableViewDataSource

extension ChartViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objectArrayForTableView.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Used to create Header/Tittle cell
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! CellForChartTable
            cell.lblForDate.text = "Date"
            if self.segmentController.selectedSegmentIndex == 0{ // For AppUsage header cell
                cell.lblForColumnOne.text = ""
                cell.lblForColumnTwo.text = self.headerArrayForTableView[segmentController.selectedSegmentIndex][0]
            }else{ //for Accomplish & Activity header cell
                cell.lblForColumnOne.text = self.headerArrayForTableView[segmentController.selectedSegmentIndex][0]
                cell.lblForColumnTwo.text = self.headerArrayForTableView[segmentController.selectedSegmentIndex][1]
            }
            return cell
        }
        
        // Used to create general cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCell", for: indexPath) as! CellForChartTable
        if let objForRow = self.objectArrayForTableView.object(at: indexPath.row - 1)  as? NSArray{
            cell.lblForDate.text = "\(General.formatedDate(date: Date(timeIntervalSince1970: objForRow[0] as! TimeInterval), formatorStr: General.DEFAULT_DATE_FORMATOR))"
            if self.segmentController.selectedSegmentIndex == 0{ // For AppUsage cell
                cell.lblForColumnOne.text = ""
                if let seconds = objForRow[1] as? Int {
                    cell.lblForColumnTwo.text = General.toHHMMSSConvertor(seconds: seconds)
                }
            }else{ //for Accomplish & Activity cell
                cell.lblForColumnOne.text = "\(objForRow[1])"
                cell.lblForColumnTwo.text = "\(objForRow[2])"
            }
        }
        return cell
    }
    
}

// MARK: - DatePickerview Methods

extension ChartViewController{
    /// Used to pull up view
    ///
    /// - Parameters:
    ///   - view: UIView which will pull up
    ///   - frame: CGRect where UIView final pull
    public func GoUp(view : UIView , frame : CGRect)  {
        view.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0.05, options: [.curveLinear], animations: {
            view.frame = frame
        })
    }
    
    /// Used to pull down view
    ///
    /// - Parameters:
    ///   - view: UIView which will pull down
    ///   - frame: CGRect of given UIView
    public func GoDown(view : UIView ,frame : CGRect)  {
        UIView.animate(withDuration: 0.3, delay: 0.05, options: [.curveLinear], animations: {
            view.frame = CGRect(x:frame.origin.x
                , y: self.view.frame.height, width: frame.size.width, height: frame.size.height)
        }){(finish) in
            if finish {
                view.isHidden = true
            }
        }
    }
    
    public func hideDatePickerView(view : UIView ,frame : CGRect)  {
        UIView.animate(withDuration: 0.0, delay: 0.0, options: [.curveLinear], animations: {
            view.frame = CGRect(x:frame.origin.x
                , y: self.view.frame.height, width: frame.size.width, height: frame.size.height)
        }){(finish) in
            if finish {
                view.isHidden = true
            }
        }
    }
    /// Used to pull down picker view with animation and to set date to button
    ///
    /// - Parameter sender: UIButton
    @IBAction func viewDonePressed(_ sender: Any) {
        if !General.isConnectedToNetwork(){
            self.showNetworkUnavailableAlert()
            perform(#selector(viewCancelPressed(_:)), with: nil, afterDelay: 0.2)
            return
        }
        if self.selectedDateIdentifier == "To"{
            self.btnForToDate.setTitle(General.formatedDate(date: self.datePicker.date, formatorStr: General.DEFAULT_DATE_FORMATOR), for: .normal)
            
            self.callGraphDataAPIs(graphHostName: self.currentgraphName, platformId: "\(self.selectedPlatformId)", strFromDate:(self.btnForFromDate.titleLabel?.text)!, strToDate: General.formatedDate(date: self.datePicker.date, formatorStr: "dd/MM/yyyy"))
            
        }else if self.selectedDateIdentifier == "From"{
            self.btnForFromDate.setTitle(General.formatedDate(date: self.datePicker.date, formatorStr: General.DEFAULT_DATE_FORMATOR), for: .normal)
            
            self.callGraphDataAPIs(graphHostName: self.currentgraphName, platformId: "\(self.selectedPlatformId)", strFromDate: General.formatedDate(date:self.datePicker.date, formatorStr: "dd/MM/yyyy"), strToDate: (self.btnForToDate.titleLabel?.text)!)
        }
        perform(#selector(viewCancelPressed(_:)), with: nil, afterDelay: 0.2)
    }
    
    /// Used to pull down picker view with animation
    ///
    /// - Parameter sender: UIButton
    @IBAction func viewCancelPressed(_ sender: UIButton) {
        self.GoDown(view: datePickerView, frame: originalRect)
    }
}



// MARK: - CalenderWeekdayXAxisValueFormator

/// Used to convert timestamp to weekday abbrevation
class CalenderWeekdayXAxisValueFormator : IAxisValueFormatter{
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let weekday = Calendar.current.component(.weekday, from: Date(timeIntervalSince1970: value))
        switch weekday {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return ""
        }
    }
}

// MARK: - CalenderDateXAxisValueFormator

/// Used to convert timestamp to dd/MM/MM format
class CalenderDateXAxisValueFormator : IAxisValueFormatter{
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return General.formatedDate(date: Date(timeIntervalSince1970: value), formatorStr: "dd/MM")
    }
}

// MARK: - CalenderDateXAxisValueFormator

/// Used to convert timestamp to minute with min as string extension
class YAxisMinValueFormator : IAxisValueFormatter{
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return (value < 1 ? "\(Int(value) * 60) sec" : "\(Int(value)) min")
    }
}

