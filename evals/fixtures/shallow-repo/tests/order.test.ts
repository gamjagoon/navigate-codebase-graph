import { handleOrder } from "../src/order-handler";

test("accepts an order", () => {
  expect(handleOrder({ customerId: "c1", amount: 3 })).toBe("c1:3");
});
