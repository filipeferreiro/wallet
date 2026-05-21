<?php

namespace App\Http\Controllers;

use App\Http\Requests\DepositRequest;
use App\Http\Requests\WithdrawRequest;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class WalletController extends Controller
{
    protected $walletService;

    public function __construct(WalletService $walletService)
    {
        $this->walletService = $walletService;
    }

    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user();
        $wallet = $user->wallet()->firstOrCreate(['user_id' => $user->id]);
        $now = Carbon::now();

        $latestTransactions = $wallet->transactions()
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        $totalDepositedMonth = $wallet->transactions()
            ->where('type', 'credit')
            ->whereMonth('created_at', $now->month)
            ->whereYear('created_at', $now->year)
            ->sum('amount');

        $totalWithdrawnMonth = $wallet->transactions()
            ->where('type', 'debit')
            ->whereMonth('created_at', $now->month)
            ->whereYear('created_at', $now->year)
            ->sum('amount');
        
        return response()->json([
            'balance' => $wallet->balance,
            'latest_transactions' => $latestTransactions,
            'metrics' => [
                'total_deposited_month' => $totalDepositedMonth,
                'total_withdrawn_month' => $totalWithdrawnMonth,
            ]
        ]);
    }

    public function deposit(DepositRequest $request): JsonResponse{
        $wallet = $request->user()->wallet()->firstOrCreate(['user_id' => $request->user()->id]);

        try{
            $updatedWallet = $this->walletService->deposit($wallet, $request->amount);
            return response()->json([
                'message' => 'Depósito realizado com sucesso!',
                'balance' => $updatedWallet->balance
            ], 200);
        }catch(\Exception $e){
            return response()->json(['error' => $e->getMessage()], $e->getCode());
        }
    }

    public function withdraw(WithdrawRequest $request): JsonResponse{
        $wallet = $request->user()->wallet()->firstOrCreate(['user_id' => $request->user()->id]);

        try{
            $updatedWallet = $this->walletService->withdraw($wallet, $request->amount);
            return response()->json([
                'message' => 'Saque realizado com sucesso!',
                'balance' => $updatedWallet->balance
            ], 200);
        }catch(\Exception $e){
            return response()->json(['error' => $e->getMessage()], $e->getCode());
        }
    }

    public function history(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallet()->firstOrCreate(['user_id' => $request->user()->id]);
        $query = $wallet->transactions()->orderBy('created_at', 'desc');

        if ($request->has('type') && in_array($request->type, ['credit', 'debit'])) {
            $query->where('type', $request->type);
        }

        if ($request->filled('start_date')) {
            $query->whereDate('created_at', '>=', $request->start_date);
        }

        if ($request->filled('end_date')) {
            $query->whereDate('created_at', '<=', $request->end_date);
        }

        $transactions = $query->paginate(10);

        return response()->json($transactions);
    }
}
