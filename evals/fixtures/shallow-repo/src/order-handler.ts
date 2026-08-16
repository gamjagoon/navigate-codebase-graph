import { OrderInput, validateOrder, saveOrder } from "./order";

export function handleOrder(input: OrderInput): string {
  validateOrder(input);
  return saveOrder(input);
}
