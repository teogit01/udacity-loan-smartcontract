// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Collateralized Loan Contract
contract CollateralizedLoan {
    // Define the structure of a loan
    struct Loan {
        address borrower;                
        // -Hint: Add a field for the lender's address
        address lender;
        uint collateralAmount;    
        // -Hint: Add fields for loan amount, interest rate, due date, isFunded, isRepaid
        uint loanAmount;
        uint interestRate;
        uint dueDate;
        bool isFunded;
        bool isRepaid;
    }

    // Create a mapping to manage the loans
    mapping(uint => Loan) public loans;
    uint public nextLoanId;

    // -Hint: Define events for loan requested, funded, repaid, and collateral claimed
    // Event for loan requested
    event LoanRequested (
        address indexed borrower,
        uint loanId, 
        uint collateralAmount, 
        uint loanAmount,
        uint interestRate,
        uint dueDate
    );  
    
    // Event for funded
    event LoanFunded (
        address indexed lender, 
        uint loanId, 
        uint loanAmount
    );
    // Event for repaid
    event LoanRepaid (
        address indexed borrower, 
        uint loanId, 
        uint repaidAmount
    );
    // Event for collateral claimed
    event LoanCollateralClaimed (
        address indexed lender, 
        uint loanId, 
        uint collateralAmount
    );

    // Custom Modifiers
    // -Hint: Write a modifier to check if a loan exists
    modifier loanExist (uint _loanId) {
        require (_loanId > 0 && _loanId <= nextLoanId, 'Loan dose not exist!');
        _;
    }
    // -Hint: Write a modifier to ensure a loan is not already funded
    modifier notFunded (uint _loanId) {
        require(!loans[_loanId].isFunded, 'Loan is already funded!');
        _;
    }

    // Modifier to check if a loan is funded and not repaid
    modifier fundedAndNotRepaid (uint _loanId) {        
        require(loans[_loanId].isFunded, 'Loan is not funded');
        require(!loans[_loanId].isRepaid, 'Loan is already repaid');
        _;
    }

    // Function to deposit collateral and request a loan
    function depositCollateralAndRequestLoan(uint _interestRate, uint _duration) external payable {
        // -Hint: Check if the collateral is more than 0
        require(msg.value > 0, 'Collateral must be greater than 0');
        // -Hint: Calculate the loan amount based on the collateralized amount
        uint loanAmount = msg.value * 2;                
        // -Hint: Increment nextLoanId and create a new loan in the loans mapping
        nextLoanId++;                
        uint dueDate = block.timestamp + _duration; 
        loans[nextLoanId] = Loan({
            borrower: msg.sender,
            lender: address(0),
            collateralAmount: msg.value,
            loanAmount: loanAmount,
            interestRate: _interestRate,
            dueDate: dueDate,
            isFunded: false,
            isRepaid: false
        });
        // -Hint: Emit an event for loan request        
        emit LoanRequested(msg.sender, nextLoanId, msg.value, loanAmount,  _interestRate, dueDate);
    }

    // Function to fund a loan
    // -Hint: Write the fundLoan function with necessary checks and logic
    function fundLoan(uint _loanId) external payable loanExist(_loanId) notFunded(_loanId) {
        // here are some logics
        // check that deposit amount is sufficient to fund the loan
        Loan storage loan = loans[_loanId];
        
        require(msg.value >= loan.loanAmount, 'Insufficient to fund this loan');
        // update loan infomation
        loan.lender = msg.sender;
        loan.isFunded = true;
        // transfer loan amount to borrower
        payable(loan.borrower).transfer(loan.loanAmount);
        // emit an event when funded
        emit LoanFunded(msg.sender, _loanId, loan.loanAmount);
    }

    // Function to repay a loan
    // -Hint: Write the repayLoan function with necessary checks and logic
    function repayLoan (uint _loanId) external payable loanExist(_loanId) fundedAndNotRepaid(_loanId) {
        Loan storage loan = loans[_loanId];        
        // calculate the total amount to be refunded
        uint totalAmount = loan.loanAmount + ( loan.loanAmount * loan.interestRate ) / 100;
        require(msg.value >= totalAmount, "Insufficient funds to repay this loan");
        // mark repaid and transfer loan amount to borrower
        loan.isRepaid = true;    
        payable(loan.lender).transfer(totalAmount);
        // emit an event when repaid        
        emit LoanRepaid(msg.sender, _loanId, totalAmount);
    }

    // Function to claim collateral on default
    // -Hint: Write the claimCollateral function with necessary checks and logic
    function claimCollateral (uint _loanId) external payable loanExist(_loanId) fundedAndNotRepaid(_loanId) {
        Loan storage loan = loans[_loanId];
        // check if it is expired
        require(block.timestamp > loan.dueDate, 'Loan is not overdue yet');
        // only the lender has the right to claim collateral
        require(msg.sender == loan.lender, "Only the lender can claim collateral");
        // mark repaid and transfer collateral to lender
        payable(loan.lender).transfer(loan.collateralAmount);
        // emit event when collateral is requested
        emit LoanCollateralClaimed(msg.sender, _loanId, loan.collateralAmount);            
    }
}