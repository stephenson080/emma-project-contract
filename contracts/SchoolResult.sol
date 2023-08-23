// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract SchoolResult is Ownable {
    enum Semesters {
        HARMATTAN,
        RAIN
    }

    struct Session {
        string name;
        bool created;
    }

    struct StudentDetails {
        string name;
        string reqNo;
        string department;
        string code;
        uint department_id;
    }

    struct Result {
        uint session;
        uint64 score;
        uint16 point;
        uint course;
        Semesters semester;
        bool created;
    }
    struct Department {
        string name;
        string dep_code;
        bool created;
    }
    struct Student {
        string name;
        string regNo;
        uint department;
    }

    struct Course {
        string name;
        string code;
        uint8 unit;
        bool created;
    }

    mapping(address => uint) private student_map;
    mapping(uint => mapping(uint => mapping(uint => mapping(uint => uint))))
        private result_map;

    mapping(uint => Student) private students;
    mapping(uint => Course) public courses;
    mapping(uint => Department) public departments;
    mapping(uint => Result) private results;
    mapping(uint => Session) public sessions;

    uint public no_of_students = 1;
    uint public no_of_departments = 1;
    uint public no_of_courses = 1;
    uint public no_of_results = 1;
    uint public no_of_sessions = 1;

    constructor() {}

    function add_student(
        address _address,
        string calldata _name,
        string calldata _reg_no,
        uint _id
    )
        external
        checkAddress0(_address)
        onlyOwner
        check_student_exist(_address)
        check_department(_id)
    {
        Student memory new_student = Student(_name, _reg_no, _id);

        student_map[_address] = no_of_students;
        students[no_of_students] = new_student;

        no_of_students++;
    }

    function edit_student(
        string calldata _name,
        string calldata _reg_no
    ) external checkAddress0(_msgSender()) check_student(_msgSender()) {
        uint student_id = student_map[_msgSender()];
        Student storage _student = students[student_id];
        _student.name = _name;
        _student.regNo = _reg_no;
    }

    function add_department(
        string calldata _name,
        string calldata _code
    ) external onlyOwner {
        Department memory new_dep = Department(_name, _code, true);
        departments[no_of_departments] = new_dep;
        no_of_departments++;
    }

    function edit_department(
        uint _id,
        string calldata _name,
        string calldata _code
    ) external onlyOwner check_department(_id) {
        Department storage _depart = departments[_id];
        _depart.dep_code = _code;
        _depart.name = _name;
    }

    function add_course(
        string calldata _name,
        string calldata _code,
        uint8 _unit
    ) external onlyOwner {
        Course memory new_course = Course(_name, _code, _unit, true);
        courses[no_of_courses] = new_course;
        no_of_courses++;
    }

    function edit_course(
        uint _id,
        string calldata _name,
        string calldata _code,
        uint8 _unit
    ) external onlyOwner check_department(_id) {
        Course storage _course = courses[_id];
        _course.code = _code;
        _course.name = _name;
        _course.unit = _unit;
    }

    function add_session(string calldata session_name) external onlyOwner {
        Session memory new_session = Session(session_name, true);
        sessions[no_of_sessions] = new_session;
        no_of_sessions++;
    }

    function edit_session(
        uint _id,
        string calldata session_name
    ) external onlyOwner check_session(_id) {
        Session storage _session = sessions[_id];
        _session.name = session_name;
    }

    function add_result(
        address _student_address,
        uint course_id,
        Semesters semester,
        uint _session_id,
        uint64 score
    )
        external
        onlyOwner
        check_student(_student_address)
        check_course(course_id)
        check_session(_session_id)
    {
        uint student_id = student_map[_student_address];
        uint16 _grade = _calculateGrade(score);

        Result memory new_result = Result(
            _session_id,
            score,
            _grade,
            course_id,
            semester,
            true
        );

        uint _semester = _get_semester_id(semester);

        result_map[student_id][_semester][_session_id][
            course_id
        ] = no_of_results;
        results[no_of_results] = new_result;

        no_of_results++;
    }

    function _view_result(
        address _student_address,
        uint course_id,
        Semesters semester,
        uint _session_id
    )
        private
        view
        check_student(_student_address)
        check_course(course_id)
        check_session(_session_id)
        returns (Result memory)
    {
        uint student_id = student_map[_student_address];

        uint _semester = _get_semester_id(semester);

        uint result_id = result_map[student_id][_semester][_session_id][
            course_id
        ];

        Result storage _result = results[result_id];

        return _result;
    }

    function student_view_result(
        uint course_id,
        Semesters semester,
        uint _session_id
    ) external view returns (Result memory) {
        Result memory _result = _view_result(
            _msgSender(),
            course_id,
            semester,
            _session_id
        );
        return _result;
    }

    function admin_view_result(
        address _student_address,
        uint course_id,
        Semesters semester,
        uint _session_id
    ) external view onlyOwner returns (Result memory) {
        Result memory _result = _view_result(
            _student_address,
            course_id,
            semester,
            _session_id
        );
        return _result;
    }

    function _view_result_report(
        address _student_address,
        uint[] calldata course_ids,
        Semesters semester,
        uint _session_id
    )
        private
        view
        check_student(_student_address)
        returns (Result[] memory, uint, uint)
    {
        // uint student_id = student_map[_student_address];
        Result[] memory _results = new Result[](course_ids.length);
        uint total_units = 0;
        uint total_points = 0;
        for (uint i = 0; i < course_ids.length; i++) {
            Result memory _result = _view_result(
                _student_address,
                course_ids[i],
                semester,
                _session_id
            );
            if (_result.created) {
                Course storage _course = courses[_result.course];
                if (_course.created) {
                    total_units += _course.unit;
                    total_points += _course.unit * _result.point;
                    _results[i] = _result;
                }
            }
        }

        return (_results, total_points, total_units);
    }

    function _student_view_result_report(
        uint[] calldata course_ids,
        Semesters semester,
        uint _session_id
    ) external view returns (Result[] memory, uint, uint) {
        return
            _view_result_report(
                _msgSender(),
                course_ids,
                semester,
                _session_id
            );
    }

    function _admin_view_result_report(
        address student_address,
        uint[] calldata course_ids,
        Semesters semester,
        uint _session_id
    ) external view returns (Result[] memory, uint, uint) {
        return
            _view_result_report(
                student_address,
                course_ids,
                semester,
                _session_id
            );
    }

    function _get_student_id(address _address) private view returns (uint) {
        return student_map[_address];
    }

    function _calculateGrade(uint64 _score) private pure returns (uint16) {
        if (_score < 40) {
            return 0;
        } else if (_score >= 40 && _score < 50) {
            return 1;
        } else if (_score >= 50 && _score < 60) {
            return 3;
        } else if (_score >= 60 && _score < 70) {
            return 4;
        } else {
            return 5;
        }
    }

    function _get_semester_id(Semesters semester) private pure returns (uint) {
        if (semester == Semesters.HARMATTAN) {
            return 0;
        } else {
            return 1;
        }
    }

    function getNumberOfStudents() external view onlyOwner returns (uint) {
        uint num = no_of_students;
        return num - 1;
    }

    function getNumberOfDepartments() external view onlyOwner returns (uint) {
        uint num = no_of_departments;
        return num - 1;
    }

    function getNumberOfCourses() external view onlyOwner returns (uint) {
        uint num = no_of_courses;
        return num - 1;
    }

    function getNumberOfResults() external view onlyOwner returns (uint) {
        uint num = no_of_results;
        return num - 1;
    }

    function getNumberOfSessions() external view onlyOwner returns (uint) {
        uint num = no_of_sessions;
        return num - 1;
    }

    function _adminGetAllStudents()
        external
        view
        onlyOwner
        returns (StudentDetails[] memory)
    {
        uint num_clone = no_of_students;
        uint num = num_clone - 1;
        StudentDetails[] memory _students = new StudentDetails[](
            no_of_students
        );
        for (uint i = 1; i <= num; i++) {
            _students[i] = _getStudent(i);
        }
        return _students;
    }

    function student_get_profile(
        address _address
    ) external view returns (StudentDetails memory) {
        uint _id = student_map[_address];
        require(_id > 0, "Student's doesn't exist");
        return _getStudent(_id);
    }

    function _getStudent(
        uint _id
    ) private view returns (StudentDetails memory) {
        Student storage _student = students[_id];
        Department storage _department = departments[_student.department];
        StudentDetails memory _details = StudentDetails(
            _student.name,
            _student.regNo,
            _department.name,
            _department.dep_code,
            _student.department
        );
        return _details;
    }

    function getAllCourse() external view returns (Course[] memory) {
        uint num_clone = no_of_courses;
        uint num = num_clone - 1;
        Course[] memory _courses = new Course[](no_of_courses);
        for (uint i = 1; i <= num; i++) {
            _courses[i] = courses[i];
        }
        return _courses;
    }

    function getAllDepartment() external view returns (Department[] memory) {
        uint num_clone = no_of_departments;
        uint num = num_clone - 1;
        Department[] memory _departments = new Department[](no_of_departments);
        for (uint i = 1; i <= num; i++) {
            _departments[i] = departments[i];
        }
        return _departments;
    }

    function getAllSessions() external view returns (Session[] memory) {
        uint num_clone = no_of_sessions;
        uint num = num_clone - 1;
        Session[] memory _sessions = new Session[](no_of_sessions);
        for (uint i = 1; i <= num; i++) {
            _sessions[i] = sessions[i];
        }
        return _sessions;
    }

    modifier checkAddress0(address _address) {
        require(_address != address(0), "BlocFi: Invalid wallet address");
        _;
    }
    modifier check_department(uint _id) {
        require(departments[_id].created, "Department doesn't exist");
        _;
    }

    modifier check_session(uint _id) {
        require(sessions[_id].created, "Session doesn't exist");
        _;
    }

    modifier check_course(uint _id) {
        require(courses[_id].created, "Course doesn't exist");
        _;
    }

    modifier check_student_exist(address _address) {
        require(
            student_map[_address] <= 0,
            "Student with Address Already Exist"
        );
        _;
    }
    modifier check_student(address _address) {
        require(student_map[_address] > 0, "Student don't exist");
        _;
    }
}
