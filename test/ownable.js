const Ownable = artifacts.require("Ownable");

contract('Ownable', (accounts) => {
  it('should update owner variable to value of first account', () => {
    return Ownable.deployed()
      .then((instance) => {
        return instance.owner();
      })
      .then((owner) => {
        assert.equal(owner.valueOf(), accounts[0]);
      });
  });

  it('should not update owner variable to an account other than first one', () => {
    return Ownable.deployed()
      .then((instance) => {
        return instance.owner();
      })
      .then((owner) => {
        assert.notEqual(owner.valueOf(), accounts[1]);
      });
  });
});
