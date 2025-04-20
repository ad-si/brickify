export default function (chai, utils) {
  chai.Assertion.addMethod("modified", function (time, delta) {
    // the property should always be there
    if (delta == null) {
      delta = 2000
    }
    new chai.Assertion(this._obj).to.have.deep.property("lastModified.date")
    // the date should be between time-delta and time
    const assertDate = new chai.Assertion(this._obj.lastModified.date)
    utils.transferFlags(this, assertDate, false)
    assertDate.within(time - delta, time)
    return this
  })

  return chai.Assertion.addMethod("cause", function (cause) {
    // the property should always be there
    new chai.Assertion(this._obj).to.have.deep.property("lastModified.cause")
    // the cause should match
    const assertCause = new chai.Assertion(this._obj.lastModified.cause)
    utils.transferFlags(this, assertCause, false)
    assertCause.equal(cause)
    return this
  })
}
