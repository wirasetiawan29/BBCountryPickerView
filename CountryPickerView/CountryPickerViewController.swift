//
//  CountryPickerViewController.swift
//  CountryPickerView
//
//  Created by Kizito Nwose on 18/09/2017.
//  Copyright © 2017 Kizito Nwose. All rights reserved.
//

import UIKit

public class CountryPickerViewController: UIViewController {

    public var searchController: UISearchController?
    fileprivate var searchResults = [Country]()
    fileprivate var isSearchMode = false
    fileprivate var sectionsTitles = [String]()
    fileprivate var countries = [String: [Country]]()
    fileprivate var hasPreferredSection: Bool {
        return dataSource.preferredCountriesSectionTitle != nil &&
            dataSource.preferredCountries.count > 0
    }
    fileprivate var showOnlyPreferredSection: Bool {
        return dataSource.showOnlyPreferredSection
    }
    internal weak var countryPickerView: CountryPickerView! {
        didSet {
            dataSource = CountryPickerViewDataSourceInternal(view: countryPickerView)
        }
    }
    
    fileprivate var dataSource: CountryPickerViewDataSourceInternal!
    
    let contentView = UIView()
    let closeButton = UIButton()
    let contentLabel = UILabel()
    let swipeThreshold: CGFloat = 200
    var viewTranslation = CGPoint(x: 0, y: 0)
    let contactsTableView = UITableView()
    let titleLabel = UILabel()
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        navigationController?.isNavigationBarHidden = true
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .coverVertical
        
        
        let height: CGFloat = view.bounds.height/2
        let xPosition: CGFloat = 0
        let width: CGFloat = view.frame.width
        let yPosition: CGFloat = view.frame.height - height
        
        contentView.frame = CGRect(
            x: xPosition,
            y: yPosition,
            width: width,
            height: height
        )
        
        contentView.backgroundColor = .white
        
//        prepareNavItem()
        
        view.addSubview(contentView)
        setupMyNewLabel(placeHolderValue: "Choose country code", labelName: "Choose country code")
        setupTableView()
        //Round the .topLeft and .topRight corners of the contentView
        contentView.layer.roundCorners([.topLeft, .topRight], radius: 20)
        contentView.layer.masksToBounds = true
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDismiss(recognizer:)))
        panGestureRecognizer.cancelsTouchesInView = false
        contentView.addGestureRecognizer(panGestureRecognizer)
        
    }
    
    fileprivate func setupMyNewLabel(placeHolderValue text: String, labelName name: String) {
        
        let myNewLabel: UILabel = {
            let lbl = UILabel()
            lbl.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 50) //setting frame here or you can change later as well
            lbl.backgroundColor = .white
            lbl.font = UIFont.boldSystemFont(ofSize: 20)
            lbl.textColor = .darkGray
            lbl.textAlignment = .center
            lbl.translatesAutoresizingMaskIntoConstraints = false //make sure this property is false when programmatically setting constraints
            return lbl
        }()
        
        myNewLabel.layer.name = name
        myNewLabel.text = text
        contentView.addSubview(myNewLabel)

        //setup your constraints here
        myNewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        myNewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        myNewLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
//        myNewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        contactsTableView.dataSource = self
        contactsTableView.delegate = self
        contentView.addSubview(contactsTableView)
        contactsTableView.translatesAutoresizingMaskIntoConstraints = false
        contactsTableView.topAnchor.constraint(equalTo: myNewLabel.topAnchor, constant: 50).isActive = true
        contactsTableView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        contactsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contactsTableView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        contactsTableView.separatorStyle = .none
        contactsTableView.backgroundView = UIView()
        prepareTableItems()
        prepareSearchBar()
    }
    
    private func setupTableView() {
        
      }
    
    // This will dismiss the VC using the 'close' button
    @objc func closeAction (_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // This will dismiss the VC using the UIPanGestureRecognizer if the yTranslation is bigger than the swipeThreshold value.
    // If yTranslation is less than the swipeThreshold value, VC will bounce back to its original height
    @objc
    func handleDismiss (recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            viewTranslation = recognizer.translation(in: view)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                guard self.viewTranslation.y > 0 else {return}
                self.view.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })
        case .ended:
            if viewTranslation.y < swipeThreshold {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.view.transform = .identity
                })
            } else {
                dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }
   
}

// UI Setup
extension CountryPickerViewController {
    
    func prepareTableItems()  {
        if !showOnlyPreferredSection {
            let countriesArray = countryPickerView.usableCountries
            let locale = dataSource.localeForCountryNameInList
            
            var groupedData = Dictionary<String, [Country]>(grouping: countriesArray) {
                let name = $0.localizedName(locale) ?? $0.name
                return String(name.capitalized[name.startIndex])
            }
            groupedData.forEach{ key, value in
                groupedData[key] = value.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.localizedName(locale) ?? lhs.name < rhs.localizedName(locale) ?? rhs.name
                })
            }
            
            countries = groupedData
            sectionsTitles = countries.keys.sorted()
        }
        
        // Add preferred section if data is available
        if hasPreferredSection, let preferredTitle = dataSource.preferredCountriesSectionTitle {
            sectionsTitles.insert(preferredTitle, at: sectionsTitles.startIndex)
            countries[preferredTitle] = dataSource.preferredCountries
        }
        
        contactsTableView.sectionIndexBackgroundColor = .clear
        contactsTableView.sectionIndexTrackingBackgroundColor = .clear
    }
    
    func prepareNavItem() {
        navigationItem.title = dataSource.navigationTitle

        // Add a close button if this is the root view controller
        if navigationController?.viewControllers.count == 1 {
            let closeButton = dataSource.closeButtonNavigationItem
            closeButton.target = self
            closeButton.action = #selector(close)
            navigationItem.leftBarButtonItem = closeButton
        }
    }
    
    func prepareSearchBar() {
        let searchBarPosition = dataSource.searchBarPosition
        if searchBarPosition == .hidden  {
            return
        }
        searchController = UISearchController(searchResultsController:  nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.hidesNavigationBarDuringPresentation = searchBarPosition == .tableViewHeader
        searchController?.definesPresentationContext = true
        searchController?.searchBar.delegate = self
        searchController?.delegate = self

        switch searchBarPosition {
        case .tableViewHeader: contactsTableView.tableHeaderView = searchController?.searchBar
        default: break
        }
    }
    
    @objc private func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

//MARK:- UITableViewDataSource
extension CountryPickerViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return isSearchMode ? 1 : sectionsTitles.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchMode ? searchResults.count : countries[sectionsTitles[section]]!.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: CountryTableViewCell.self)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? CountryTableViewCell
            ?? CountryTableViewCell(style: .default, reuseIdentifier: identifier)
        
        let country = isSearchMode ? searchResults[indexPath.row]
            : countries[sectionsTitles[indexPath.section]]![indexPath.row]

        var name = country.localizedName(dataSource.localeForCountryNameInList) ?? country.name
        if dataSource.showCountryCodeInList {
            name = "\(name) (\(country.code))"
        }
        if dataSource.showPhoneCodeInList {
            name = "\(name) (\u{202A}\(country.phoneCode)\u{202C})"
        }
        cell.imageView?.image = country.flag
        
        cell.flgSize = dataSource.cellImageViewSize
        cell.imageView?.clipsToBounds = true

        cell.imageView?.layer.cornerRadius = dataSource.cellImageViewCornerRadius
        cell.imageView?.layer.masksToBounds = true
        
        cell.textLabel?.text = name
        cell.textLabel?.font = dataSource.cellLabelFont
        if let color = dataSource.cellLabelColor {
            cell.textLabel?.textColor = color
        }
        cell.accessoryType = country == countryPickerView.selectedCountry &&
            dataSource.showCheckmarkInList ? .checkmark : .none
        cell.separatorInset = .zero
        return cell
    }
    
}

//MARK:- UITableViewDelegate
extension CountryPickerViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = dataSource.sectionTitleLabelFont
            if let color = dataSource.sectionTitleLabelColor {
                header.textLabel?.textColor = color
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = isSearchMode ? searchResults[indexPath.row]
            : countries[sectionsTitles[indexPath.section]]![indexPath.row]

        searchController?.isActive = false
        searchController?.dismiss(animated: false, completion: nil)
        
        let completion = {
            self.countryPickerView.selectedCountry = country
        }
        // If this is root, dismiss, else pop
        if navigationController?.viewControllers.count == 1 {
            navigationController?.dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: true, completion: completion)
        }
    }
    
}

// MARK:- UISearchResultsUpdating
extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        isSearchMode = false
        if let text = searchController.searchBar.text, text.count > 0 {
            isSearchMode = true
            searchResults.removeAll()
            
            var indexArray = [Country]()
            
            if showOnlyPreferredSection && hasPreferredSection,
                let array = countries[dataSource.preferredCountriesSectionTitle!] {
                indexArray = array
            } else if let array = countries[String(text.capitalized[text.startIndex])] {
                indexArray = array
            }

            searchResults.append(contentsOf: indexArray.filter({
                let name = ($0.localizedName(dataSource.localeForCountryNameInList) ?? $0.name).lowercased()
                let code = $0.code.lowercased()
                let query = text.lowercased()
                return name.hasPrefix(query) || (dataSource.showCountryCodeInList && code.hasPrefix(query))
            }))
        }
        contactsTableView.reloadData()
    }
}

// MARK:- UISearchBarDelegate
extension CountryPickerViewController: UISearchBarDelegate {
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Hide the back/left navigationItem button
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Show the back/left navigationItem button
        prepareNavItem()
        navigationItem.hidesBackButton = false
    }
}

// MARK:- UISearchControllerDelegate
// Fixes an issue where the search bar goes off screen sometimes.
extension CountryPickerViewController: UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = false
    }
}

// MARK:- CountryTableViewCell.
class CountryTableViewCell: UITableViewCell {
    
    var flgSize: CGSize = .zero
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame.size = flgSize
        imageView?.center.y = contentView.center.y
    }
}


// MARK:- An internal implementation of the CountryPickerViewDataSource.
// Returns default options where necessary if the data source is not set.
class CountryPickerViewDataSourceInternal: CountryPickerViewDataSource {
    
    private unowned var view: CountryPickerView
    
    init(view: CountryPickerView) {
        self.view = view
    }
    
    var preferredCountries: [Country] {
        return view.dataSource?.preferredCountries(in: view) ?? preferredCountries(in: view)
    }
    
    var preferredCountriesSectionTitle: String? {
        return view.dataSource?.sectionTitleForPreferredCountries(in: view)
    }
    
    var showOnlyPreferredSection: Bool {
        return view.dataSource?.showOnlyPreferredSection(in: view) ?? showOnlyPreferredSection(in: view)
    }
    
    var sectionTitleLabelFont: UIFont {
        return view.dataSource?.sectionTitleLabelFont(in: view) ?? sectionTitleLabelFont(in: view)
    }

    var sectionTitleLabelColor: UIColor? {
        return view.dataSource?.sectionTitleLabelColor(in: view)
    }
    
    var cellLabelFont: UIFont {
        return view.dataSource?.cellLabelFont(in: view) ?? cellLabelFont(in: view)
    }
    
    var cellLabelColor: UIColor? {
        return view.dataSource?.cellLabelColor(in: view)
    }
    
    var cellImageViewSize: CGSize {
        return view.dataSource?.cellImageViewSize(in: view) ?? cellImageViewSize(in: view)
    }
    
    var cellImageViewCornerRadius: CGFloat {
        return view.dataSource?.cellImageViewCornerRadius(in: view) ?? cellImageViewCornerRadius(in: view)
    }
    
    var navigationTitle: String? {
        return view.dataSource?.navigationTitle(in: view)
    }
    
    var closeButtonNavigationItem: UIBarButtonItem {
        guard let button = view.dataSource?.closeButtonNavigationItem(in: view) else {
            return UIBarButtonItem(title: "Close", style: .done, target: nil, action: nil)
        }
        return button
    }
    
    var searchBarPosition: SearchBarPosition {
        return view.dataSource?.searchBarPosition(in: view) ?? searchBarPosition(in: view)
    }
    
    var showPhoneCodeInList: Bool {
        return true
//        return view.dataSource?.showPhoneCodeInList(in: view) ?? showPhoneCodeInList(in: view)
    }
    
    var showCountryCodeInList: Bool {
        return view.dataSource?.showCountryCodeInList(in: view) ?? showCountryCodeInList(in: view)
    }
    
    var showCheckmarkInList: Bool {
        return view.dataSource?.showCheckmarkInList(in: view) ?? showCheckmarkInList(in: view)
    }
    
    var localeForCountryNameInList: Locale {
        return view.dataSource?.localeForCountryNameInList(in: view) ?? localeForCountryNameInList(in: view)
    }
    
    var excludedCountries: [Country] {
        return view.dataSource?.excludedCountries(in: view) ?? excludedCountries(in: view)
    }
}

extension CALayer {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let roundingSize = CGSize(width: radius, height: radius)
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: roundingSize)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.mask = mask
    }
}
