// Importing necessary modules and functions from Hardhat and Chai for testing
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

// Describing a test suite for the CollateralizedLoan contract
describe("CollateralizedLoan", function () {
  // A fixture to deploy the contract before each test. This helps in reducing code repetition.
  async function deployCollateralizedLoanFixture() {
    // Deploying the CollateralizedLoan contract and returning necessary variables
      const [owner, borrower, lender] = await ethers.getSigners();
      const LoanFactory = await ethers.getContractFactory(
          "CollateralizedLoan"
      );
      const loanContract = await LoanFactory.deploy();
      return { loanContract, owner, borrower, lender };    
  }

  // Test suite for the loan request functionality
  describe("Loan Request", function () {
    it("Should let a borrower deposit collateral and request a loan", async function () {
      // Loading the fixture
      const { loanContract, borrower } = await loadFixture(
        deployCollateralizedLoanFixture
      );

      const durationInDays = 30;
      const interestRate = 7;

      const tx = await loanContract
            .connect(borrower)
            .depositCollateralAndRequestLoan(ethers.parseEther("1"), interestRate, durationInDays)

      const receipt = await tx.wait();

      const loanId = 0; // or however you track the newly created loan
      const loan = await loanContract.loans(loanId);

      // 2. Retrieve the block that included the transaction
      const minedBlock = await ethers.provider.getBlock(receipt.blockNumber);
      const actualBlockTimestamp = minedBlock.timestamp;
      const dueDate = actualBlockTimestamp + (durationInDays);

      expect(loan.collateralAmount).to.equal(ethers.parseEther("1"));
      expect(loan.interestRate).to.equal(7);
      expect(loan.dueDate).to.be.closeTo(dueDate, 5); // within 5 seconds
      expect(loan.borrower).to.equal(borrower.address);
    });
  });
      
  // Test suite for funding a loan
  describe("Funding a Loan", function () {
    it("Allows a lender to fund a requested loan", async function () {
      // Loading the fixture
      const { loanContract, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);

      // Borrower requests a loan
      await loanContract
        .connect(borrower)
        .depositCollateralAndRequestLoan(ethers.parseEther("1"), 7, 30);

      // Lender funds the loan
      await loanContract.connect(lender).fundLoan(0, { value: ethers.parseEther("1") });

      // Verify the loan funding
      const loan = await loanContract.loans(0);
      expect(loan.lender).to.equal(lender.address);
      expect(loan.isFunded).to.equal(true);
    });
  });

  // Test suite for repaying a loan
  describe("Repaying a Loan", function () {
    it("Enables the borrower to repay the loan fully", async function () {
      // Loading the fixture
      const { loanContract, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);

      // Borrower requests a loan
      await loanContract
        .connect(borrower)
        .depositCollateralAndRequestLoan(ethers.parseEther("1"), 7, 30);

      // Lender funds the loan
      await loanContract.connect(lender).fundLoan(0, { value: ethers.parseEther("1") });

      // Calculate the repayment amount (principal + interest)
      const principal = ethers.parseEther("1"); 
      const interestRate = 7;           
      // Convert the interestRate to a bigint
      const interestRateBn = BigInt(interestRate);
      const interest = (principal * interestRateBn) / 100n;
      const repaymentAmount = principal + interest;

      // Borrower repays the loan
      await loanContract.connect(borrower).repayLoan(0, { value: repaymentAmount });

      // Verify the loan repayment
      const loan = await loanContract.loans(0);
      expect(loan.isRepaid).to.equal(true);
    });
  });

  // Test suite for claiming collateral
  describe("Claiming Collateral", function () {
    it("Permits the lender to claim collateral if the loan isn't repaid on time", async function () {
      // Loading the fixture
      const { loanContract, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);

      // Borrower requests a loan
      await loanContract
        .connect(borrower)
        .depositCollateralAndRequestLoan(ethers.parseEther("1"), 7, 30);

      // Lender funds the loan
      await loanContract.connect(lender).fundLoan(0, { value: ethers.parseEther("1") });

      // Increase the time by 2 days
      await ethers.provider.send("evm_increaseTime", [2 * 24 * 60 * 60]);


      // Claim the collateral
      await loanContract.connect(lender).claimCollateral(0, { value: ethers.parseEther("1") });

      // Verify the collateral claim
      const loan = await loanContract.loans(0);
      expect(loan.isRepaid).to.equal(false);
    });
  });
});
