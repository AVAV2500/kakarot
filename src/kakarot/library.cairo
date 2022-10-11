// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

// OpenZeppelin dependencies
from openzeppelin.access.ownable.library import Ownable

// Internal dependencies
from kakarot.model import model
from kakarot.instructions import EVMInstructions
from kakarot.execution_context import ExecutionContext
from utils.utils import Helpers

namespace Kakarot {
    func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
        Ownable.initializer(owner);
        return ();
    }

    func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        code: felt*, calldata: felt*
    ) {
        alloc_locals;

        // load helper hints
        Helpers.setup_python_defs();

        // generate instructions set
        let instructions: felt* = EVMInstructions.generate_instructions();

        // prepare execution context
        let (ctx: model.ExecutionContext) = internal.init_execution_context(code, calldata);

        // start execution
        run(instructions, ctx);

        return ();
    }

    func run{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        instructions: felt*, ctx: model.ExecutionContext
    ) {
        alloc_locals;

        // decode and execute
        EVMInstructions.decode_and_execute(instructions, ctx);

        // for debugging purpose
        ExecutionContext.dump(ctx);

        // check if execution should be stopped
        let (stopped) = ExecutionContext.is_stopped(ctx);

        // terminate execution
        if (stopped == TRUE) {
            return ();
        }

        // continue execution
        run(instructions, ctx);

        return ();
    }
}

namespace internal {
    func init_execution_context{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        code: felt*, calldata: felt*
    ) -> (ctx: model.ExecutionContext) {
        alloc_locals;
        let (empty_return_data: felt*) = alloc();
        let (empty_stopped: felt*) = alloc();
        let initial_pc = 0;
        let (pc: felt*) = alloc();
        assert [pc] = initial_pc;
        let (steps: model.ExecutionStep*) = alloc();

        let (code_len) = Helpers.get_len(code);
        let ctx: model.ExecutionContext = model.ExecutionContext(
            code=code,
            code_len=code_len,
            calldata=calldata,
            pc=pc,
            stopped=empty_stopped,
            return_data=empty_return_data,
            steps=steps,
        );
        return (ctx=ctx);
    }
}