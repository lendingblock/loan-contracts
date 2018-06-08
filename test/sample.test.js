const Sample = artifacts.require("Sample");

contract('Sample', (accounts) => {

  it('should update owner variable to value of first account', async () => {
    const instance = await Sample.deployed();
    const o = await instance.owner();
    assert.equal(o.valueOf(), accounts[0]);
  });

  it('should not update owner variable to an account other than first one', async () => {
    const instance = await Sample.deployed();
    const o = await instance.owner();
    assert.notEqual(o.valueOf(), accounts[1]);
  });
});
