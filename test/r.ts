import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const R = await ethers.getContractFactory("SchoolResult");
    const l = await R.deploy();

    await l.connect(owner).add_department("Computer Science", "CSC");

    await l
      .connect(owner)
      .add_student(otherAccount.address, "Stephen", "281278", 1);

    await l.connect(owner).add_student(owner.address, "Stephen", "281278", 1);

    const _s = await l._adminGetAllStudents();
    console.log(_s);
  }

  deployOneYearLockFixture();
});
