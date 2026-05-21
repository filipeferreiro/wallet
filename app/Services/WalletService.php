<?php

    namespace App\Services;
    use App\Models\Wallet;
    use App\Models\Transaction;
    use Illuminate\Support\Facades\DB;
    use Exception;

    class WalletService{
        public function deposit(Wallet $wallet, float $amount): Wallet{
            if($amount <= 0){
                throw new Exception("O deposito não pode ser menor ou igual a zero.");
            }

            return DB::transaction(function() use($wallet, $amount){
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

        public function withdraw(Wallet $wallet, float $amount): Wallet{
            if($amount <= 0){
                throw new Exception("O valor de saque não pode ser menor ou igual a zero.");
            }

            if(round($amount, 2) != $amount){
                throw new Exception("Não é permitido sacar valores fracionados abaixo de R$ 0,01.");
            }

            return DB::transaction(function() use($wallet, $amount){
                $wallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

                if($wallet->balance < $amount){
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
