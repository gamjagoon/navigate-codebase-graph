import { OrderInput, validateOrder, saveOrder } from "./order";

export function postOrder(input: OrderInput): string {
  validateOrder(input);
  return saveOrder(input);
}
