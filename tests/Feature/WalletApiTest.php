<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Translate\HasApiTokens;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WalletApiTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $wallet;

    protected function setUp(): void{
        parent::setUp();

        $this->user = User::factory()->create();
        $this->wallet = $this->user->wallet()->create(['balance' => 0.00]);

        Sanctum::actingAs($this->user);
    }

    public function test_deposit_money_sucess(){
        $response = $this->postJson('/api/wallet/deposit', [
            'amount' => 100.00,
        ]);

        $response->assertStatus(200)
        ->assertJsonStructure([
            'message',
            'balance'
        ]);

        $this->assertDatabaseHas('wallets', [
            'id' => $this->wallet->id,
            'balance' => 100.00,
        ]);

        $this->assertDatabaseHas('transactions', [
            'wallet_id' => $this->wallet->id,
            'amount' => 100.00,
            'type' => 'credit',
            'balance_after' => 100.00,
        ]);
    }

    public function test_deposit_requires_amount()
    {
        $response = $this->postJson('/api/wallet/deposit', [
            'amount' => -50.00
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['amount']);

        $this->assertEquals(0.00, $this->wallet->fresh()->balance);
    }

    public function test_user_withdraw_success()
    {
        // Força um saldo inicial na carteira para poder sacar
        $this->wallet->update(['balance' => 300.00]);

        $response = $this->postJson('/api/wallet/withdraw', [
            'amount' => 120.00
        ]);

        $response->assertStatus(200);

        // O saldo restante deve ser 180.00
        $this->assertDatabaseHas('wallets', [
            'id' => $this->wallet->id,
            'balance' => 180.00
        ]);

        // O histórico deve conter o débito
        $this->assertDatabaseHas('transactions', [
            'wallet_id' => $this->wallet->id,
            'type' => 'debit',
            'amount' => 120.00,
            'balance_after' => 180.00
        ]);
    }

    public function test_user_withdraw_error()
    {
        $this->wallet->update(['balance' => 50.00]);

        $response = $this->postJson('/api/wallet/withdraw', [
            'amount' => 100.00
        ]);

        // Deve estourar a Exception do Service tratada com erro 422
        $response->assertStatus(422)
                 ->assertJson([
                     'error' => 'Saldo insuficiente para saque.'
                 ]);

        // O saldo deve permanecer intacto (atômico)
        $this->assertEquals(50.00, $this->wallet->fresh()->balance);
    }

    public function test_withdraw_fractioned_amounts_error()
    {
        $this->wallet->update(['balance' => 100.00]);

        // Tentativa de saque com 3 casas decimais (fração de centavo)
        // Agora validado no request layer ao invés de só no service
        $response = $this->postJson('/api/wallet/withdraw', [
            'amount' => 10.005 
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['amount']);

        // Operação atômica: nenhum valor deve ser descontado
        $this->assertEquals(100.00, $this->wallet->fresh()->balance);
    }
}
