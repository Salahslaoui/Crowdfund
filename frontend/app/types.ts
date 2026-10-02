
declare global {
    interface Window {
        ethereum?: any;
    }
}

export interface Campaign {
    creator: string;
    goal: bigint;
    deadline: bigint;
    totalFunded: bigint;
    claimed: boolean;
}