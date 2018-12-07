//
//  ViewController.swift
//  HomeWork - Swift -Урок номер 35. UITableView Search.
//
//  Created by Oleksandr Bardashevskyi on 12/4/18.
//  Copyright © 2018 Oleksandr Bardashevskyi. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    @IBOutlet weak var searchBar : UISearchBar!
    @IBOutlet weak var segmentedControl : UISegmentedControl!
    
    enum sortedBy : Int {
        case date = 0
        case firstName = 1
        case lastName = 2
    }
    
    @IBAction func sortedCellSegmentedControl(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == sortedBy.date.rawValue {
            let sortArray = self.sortedByMonth(array: self.students)
            self.students = sortArray
            self.generateSectionInBackgroundFromArray(array: self.students, withFilter: self.searchBar.text!, segmentValue: sender.selectedSegmentIndex)

        } else if sender.selectedSegmentIndex == sortedBy.firstName.rawValue {
            let sortArray = self.students.sorted { (s1, s2) -> Bool in
                return s2.firstName > s1.firstName
            }
            self.students = sortArray
            self.generateSectionInBackgroundFromArray(array: self.students, withFilter: self.searchBar.text!, segmentValue: sender.selectedSegmentIndex)
        } else if sender.selectedSegmentIndex == sortedBy.lastName.rawValue {
            let sortArray = self.students.sorted { (s1, s2) -> Bool in
                return s2.lastName > s1.lastName
            }
            self.students = sortArray
            self.generateSectionInBackgroundFromArray(array: self.students, withFilter: self.searchBar.text!, segmentValue: sender.selectedSegmentIndex)
        }
        
        self.tableView.reloadData()
    }
    
    
    let month = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "Decemver"]
    var students = [OBStudent]()
    var studentsAndSections = [OBSection]()
    var currentOperation : Operation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var studentsArray = [OBStudent]()
        for _ in 1...500 {
            let student = OBStudent()
            student.firstName = randomName()
            student.lastName = randomName()
            student.dateOfBirth = randomDateOfBirth()
            studentsArray.append(student)
        }
        self.students = self.sortedByMonth(array: studentsArray)
        
        self.generateSectionInBackgroundFromArray(array: self.students, withFilter: self.searchBar.text!, segmentValue: self.segmentedControl.selectedSegmentIndex)
    }
    //MARK: UITableViewDataSource
    
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? { //справа леттер бар
        var array = [String]()
        for section in self.studentsAndSections {
            array.append(section.sectionName)
        }
        return array
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.studentsAndSections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.studentsAndSections[section].sectionName
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.studentsAndSections[section].sectionsArray.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifire = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifire)
        
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: identifire)
        }
        
        let group = self.studentsAndSections[indexPath.section]
        let studentSorted = group.sectionsArray.sorted { (s1, s2) -> Bool in
            return s2.firstName != s1.firstName ? s2.firstName > s1.firstName : s2.lastName > s1.lastName
        }
        let student = studentSorted[indexPath.row]
        
        
        cell?.textLabel?.text = "\(student.firstName) \(student.lastName)"
        cell?.detailTextLabel?.text = student.dateOfBirth.padding(toLength: 3, withPad: "", startingAt: 0)
        
        return cell!
    }

    //MARK: - Functions:
    func randomName () -> String {
        
        func randomLetter(count: Int) -> Int {
            return Int(arc4random())%count
        }
        
        var name = ""
        var arrayLoud = ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z"]
        var arrayVowels = ["a", "e", "i", "o", "u"]
        var arrayAlphabet = arrayVowels
        arrayAlphabet += arrayLoud
        
        for i in 2..<10 {
            if i == 2 {
                name.append(arrayAlphabet[randomLetter(count: arrayAlphabet.count)])
            }
            if (name.hasPrefix("a") || name.hasPrefix("e") || name.hasPrefix("i") || name.hasPrefix("o") || name.hasPrefix("u")) {
                name.append(i % 2 == 0 ? arrayLoud[randomLetter(count: arrayLoud.count)] : arrayVowels[randomLetter(count: arrayVowels.count)])
            } else {
                name.append(i % 2 == 1 ? arrayLoud[randomLetter(count: arrayLoud.count)] : arrayVowels[randomLetter(count: arrayVowels.count)])
            }
        }
        return name.capitalized
    }
    
    func generateSectionInBackgroundFromArray(array: [OBStudent], withFilter filterString: String, segmentValue: Int) { //функция на главном потоке
        self.currentOperation?.cancel()
        weak var selfWeak : ViewController? = self
        self.currentOperation = BlockOperation.init(block: {
            let sectionArray = selfWeak!.generateSectionsFromArray(array: array, withFilter: filterString, segmentValue: segmentValue)
            DispatchQueue.main.async {
                selfWeak!.studentsAndSections = sectionArray
                selfWeak!.tableView.reloadData()
                self.currentOperation = nil
            }
        })
        self.currentOperation?.start()
    }
    func generateSectionsFromArray(array: [OBStudent], withFilter filterString: String, segmentValue: Int) -> [OBSection]{
        var currentLetter = ""
        var sectionsArray = [OBSection]()
        
        func optimizationSorted(by: String, student: OBStudent, count: Int) {
            let year = by.prefix(count)
            var section = OBSection()
            if currentLetter != year {
                section.sectionName = String(year)
                currentLetter = String(year)
                sectionsArray.append(section)
            } else {
                section = sectionsArray.last!
            }
            section.sectionsArray.append(student)
        }
        
        for student in array {
            let newString = student.firstName.lowercased() + " " + student.lastName.lowercased()
            if newString.range(of: filterString.lowercased()) == nil && filterString.count > 0 {
                continue
            }
            if segmentValue == sortedBy.date.rawValue {
                optimizationSorted(by: student.dateOfBirth, student: student, count: student.dateOfBirth.count)
            } else if segmentValue == sortedBy.firstName.rawValue {
                optimizationSorted(by: student.firstName, student: student, count: 1)
            } else if segmentValue == sortedBy.lastName.rawValue {
                optimizationSorted(by: student.lastName, student: student, count: 1)
            }
        }
        return sectionsArray
    }
    func randomDateOfBirth() -> String {
        
        let dateOfBirth = "\(self.month[Int(arc4random()%12)])"
        return dateOfBirth
    }
    func sortedByMonth(array: [OBStudent]) -> [OBStudent] {
        var sortedArray = [OBStudent]()
        var janArray = [OBStudent]()
        var febArray = [OBStudent]()
        var marArray = [OBStudent]()
        var aprArray = [OBStudent]()
        var mayArray = [OBStudent]()
        var junArray = [OBStudent]()
        var julArray = [OBStudent]()
        var augArray = [OBStudent]()
        var sepArray = [OBStudent]()
        var octArray = [OBStudent]()
        var novArray = [OBStudent]()
        var decArray = [OBStudent]()
        
        for student in array {
            switch student {
            case let stud where stud.dateOfBirth == self.month[0]:
                janArray.append(student)
            case let stud where stud.dateOfBirth == self.month[1]:
                febArray.append(student)
            case let stud where stud.dateOfBirth == self.month[2]:
                marArray.append(student)
            case let stud where stud.dateOfBirth == self.month[3]:
                aprArray.append(student)
            case let stud where stud.dateOfBirth == self.month[4]:
                mayArray.append(student)
            case let stud where stud.dateOfBirth == self.month[5]:
                junArray.append(student)
            case let stud where stud.dateOfBirth == self.month[6]:
                julArray.append(student)
            case let stud where stud.dateOfBirth == self.month[7]:
                augArray.append(student)
            case let stud where stud.dateOfBirth == self.month[8]:
                sepArray.append(student)
            case let stud where stud.dateOfBirth == self.month[9]:
                octArray.append(student)
            case let stud where stud.dateOfBirth == self.month[10]:
                novArray.append(student)
            case let stud where stud.dateOfBirth == self.month[11]:
                decArray.append(student)
            default: break
            }
        }
        sortedArray += janArray
        sortedArray += febArray
        sortedArray += marArray
        sortedArray += aprArray
        sortedArray += mayArray
        sortedArray += junArray
        sortedArray += julArray
        sortedArray += augArray
        sortedArray += sepArray
        sortedArray += octArray
        sortedArray += novArray
        sortedArray += decArray
        
        return sortedArray
    }
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
//MARK: - UISearchBarDelegate
extension ViewController : UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("textDidChange \(searchText)")
        self.generateSectionInBackgroundFromArray(array: self.students, withFilter: self.searchBar.text!, segmentValue: self.segmentedControl.selectedSegmentIndex)
    }
}
