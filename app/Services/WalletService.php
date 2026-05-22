<?php

namespace App\Services;

use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;
use Exception;

class WalletService
{
    /**
     * Validação de precisão monetária deve usar regex ao invés de float comparison
     * para evitar problemas de precisão em ponto flutuante IEEE 754.
     */
    private function validateMonetaryPrecision(float $amount): void
    {
        // Verifica se o valor tem no máximo 2 casas decimais
        if (!preg_match('/^\d+(\.\d{1,2})?$/', (string)$amount)) {
            throw new Exception("O valor deve ter no máximo 2 casas decimais (centavos).");
        }
    }

    private function validatePositiveAmount(float $amount): void
    {
        if ($amount <= 0) {
            throw new Exception("O valor deve ser maior que zero.");
        }
    }

    public function deposit(Wallet $wallet, float $amount): Wallet
    {
        $this->validatePositiveAmount($amount);
        $this->validateMonetaryPrecision($amount);

        return DB::transaction(function() use ($wallet, $amount) {
            $wallet = Wallet::where("id", $wallet->id)->lockForUpdate()->first();
            $wallet->balance += $amount;
            $wallet->save();

            $wallet->transactions()->create([
                'type' => 'credit',
                'amount' => $amount,
                'balance_after' => $wallet->balance
            ]);

            return $wallet;
        });
    }

    public function withdraw(Wallet $wallet, float $amount): Wallet
    {
        $this->validatePositiveAmount($amount);
        $this->validateMonetaryPrecision($amount);

        return DB::transaction(function() use ($wallet, $amount) {
            $wallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

            if ($wallet->balance < $amount) {
                throw new Exception("Saldo insuficiente para saque.");
            }

            $wallet->balance -= $amount;
            $wallet->save();

            $wallet->transactions()->create([
                'type' => 'debit',
                'amount' => $amount,
                'balance_after' => $wallet->balance
            ]);

            return $wallet;
        });
    }
}
