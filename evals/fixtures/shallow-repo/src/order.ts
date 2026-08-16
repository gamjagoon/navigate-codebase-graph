export type OrderInput = { customerId: string; amount: number };

export function validateOrder(input: OrderInput): void {
  if (!input.customerId || input.amount <= 0) throw new Error("invalid order");
}

export function saveOrder(input: OrderInput): string {
  return `${input.customerId}:${input.amount}`;
}
