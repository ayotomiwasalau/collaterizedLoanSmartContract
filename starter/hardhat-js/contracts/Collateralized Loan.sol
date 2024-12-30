// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Collateralized Loan Contract
contract CollateralizedLoan {
    // Define the structure of a loan
    struct Loan {
        address borrower;
        address payable lender;
        uint collateralAmount;
        uint loanAmount;
        uint interestRate;
        uint dueDate;
        bool isFunded;
        bool isRepaid;
    }

    // Create a mapping to manage the loans
    mapping(uint => Loan) public loans;
    uint public nextLoanId;

    //  Define events for loan requested, funded, repaid, and collateral claimed
    event LoanRequested(uint loanId, address borrower, uint loanAmount, uint interestRate, uint dueDate); 
    event LoanFunded(uint loanId, address lender,address borrower, uint loanAmount, uint collateralAmount, uint interestRate, uint dueDate);
    event LoanRepaid(uint loanId, address borrower, uint loanAmount, uint interestRate, uint dueDate, uint repaymentAmount);
    event CollateralClaimed(uint loanId, address lender, uint collateralAmount, uint loanAmount, uint interestRate, uint dueDate);    

    // Custom Modifiers
    //  Write a modifier to check if a loan exists
    modifier loanExists(uint _loanId) {
        require(loans[_loanId].borrower != address(0), "Loan does not exist"); //noteinfo
        _;
    }
    //  Write a modifier to ensure a loan is not already funded
    modifier loanNotFunded(uint _loanId) {
        require(loans[_loanId].isFunded == false, "Loan is already funded");
        _;
    }

    modifier loanFunded(uint _loanId) {
        require(loans[_loanId].isFunded, "Loan is not funded");
        _;
    }

    // Function to deposit collateral and request a loan
    function depositCollateralAndRequestLoan(uint _collateralAmount, uint _interestRate, uint _duration) external payable {
        //  Check if the collateral is more than 0
        require(_collateralAmount > 0, "Collateral amount must be greater than 0");
        // Check if the loand duration is more than 0
        require(_duration > 0, "Loan duration must be greater than 0");
        uint loanId = nextLoanId++;
        //  Calculate the loan amount based on the collateralized amount
        uint loanAmount = _collateralAmount;

        //  create a new loan in the loans mapping

        Loan storage loan = loans[loanId];
        loan.borrower = msg.sender;
        loan.lender = payable(address(0));
        loan.collateralAmount = _collateralAmount;
        loan.loanAmount = loanAmount;
        loan.interestRate = _interestRate;
        loan.dueDate = block.timestamp + _duration;
        loan.isFunded = false;
        loan.isRepaid = false;
        
        //  Emit an event for loan request
        emit LoanRequested(loanId, loan.borrower, loan.loanAmount, loan.interestRate, loan.dueDate);
        
    }

    // Function to fund a loan
    //  Write the fundLoan function with necessary checks and logic
    function fundLoan(uint _loanId) external payable  loanExists(_loanId) loanNotFunded(_loanId) {
        Loan storage loan = loans[_loanId];

        require(
            msg.sender != loan.borrower,
            "Borrower cannot fund their own loan"
        );

        //  Check if the loan amount matches the sent value
        require(loan.loanAmount == msg.value, "Incorrect funding for loan amount");

        //  Transfer the loan amount to the borrower
        payable(loan.borrower).transfer(msg.value);

         //  Set the lender and mark the loan as funded
        loan.lender = payable(msg.sender);
        loan.isFunded = true;
        
        //  Emit an event for loan funded
        emit LoanFunded(_loanId, msg.sender, loan.borrower, loan.loanAmount, loan.collateralAmount, loan.interestRate, loan.dueDate);

    }


    // Function to repay a loan
    //  Write the repayLoan function with necessary checks and logic
    function repayLoan(uint _loanId) external payable loanExists(_loanId) loanFunded(_loanId) {
        Loan storage loan = loans[_loanId];

        // Calculate the repayment amount including interest
        uint repaymentAmount = loan.loanAmount + (loan.loanAmount * loan.interestRate / 100);

        //  Check if the loan amount matches the sent value
        require(msg.value == repaymentAmount, "Incorrect repayment amount");

        //  Transfer the loan amount to the lender
        payable(loan.lender).transfer(msg.value);

        //  Mark the loan as repaid
        loan.isRepaid = true;

        //  Emit an event for loan repaid
        emit LoanRepaid(_loanId, msg.sender, msg.value, loan.interestRate, loan.dueDate, repaymentAmount);

    }

    // Function to claim collateral on default
    //  Write the claimCollateral function with necessary checks and logic
    function claimCollateral(uint _loanId) external payable loanExists(_loanId) {
        Loan storage loan = loans[_loanId];

        //  Check if the loan is funded and not repaid
        require(loan.isFunded == true && loan.isRepaid == false, "Loan is not defaulted");

        //  Check if the due date has passed
        require(block.timestamp > loan.dueDate, "Loan is not due yet");

        //  Transfer the collateral amount to the lender
        payable(loan.lender).transfer(loan.collateralAmount);

        //  Emit an event for collateral claimed
        emit CollateralClaimed(_loanId, loan.lender, loan.collateralAmount, loan.loanAmount, loan.interestRate, loan.dueDate);

    }
}