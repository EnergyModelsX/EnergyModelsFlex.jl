using JuMP

function get_values(m, variable, node, iterable)
    return [JuMP.value(m[variable][node, t]) for t ∈ iterable]
end

function check_cyclic_sequence(arr::Vector, min_up_value::Int, min_down_value::Int)::Bool
    n = length(arr)

    # Function to count consecutive values (zeros or non-zeros)
    function count_consecutive(start_idx, condition)
        count = 0
        j = start_idx
        while condition(arr[j])
            count += 1
            j = mod(j, n) + 1  # Move in a circular way (handle cycle)
            if j == start_idx  # Stop if we are back to the start
                break
            end
        end
        return count, j
    end

    izzero(x) = abs(x) <= 1e-10
    iznonzero(x) = !izzero(x)

    i = 1  # Starting index

    while i <= n
        if izzero(arr[i])
            # Count consecutive zeros starting from index i
            count_zeros, next_idx = count_consecutive(i, x -> izzero(x))

            if count_zeros < min_down_value
                if i < min_down_value
                    # If were in the first segment, the rest of the leading zeros to this
                    # segment might be at the end of the array
                    needed_zeros = min_down_value - count_zeros
                    last_zeros = all(izzero(v) for v ∈ arr[end-needed_zeros+1:end])
                    if last_zeros
                        i = next_idx
                        continue
                    end
                end
                return false
            end
            if next_idx < i
                break
            end
            i = next_idx  # Move to the next non-zero element
        else
            # Count consecutive non-zero values starting from index i
            count_nonzeros, next_idx = count_consecutive(i, x -> iznonzero(x))
            if count_nonzeros < min_up_value
                if i < min_up_value
                    # If were in the first segment, the rest of the leading non-zeros to
                    # this segment might be at the end of the array.
                    needed_non_zeros = min_up_value - count_nonzeros
                    last_non_zeros =
                        all(iznonzero(v) for v ∈ arr[end-needed_non_zeros+1:end])
                    if last_non_zeros
                        i = next_idx
                        continue
                    end
                end
                return false
            end
            if next_idx < i
                break
            end
            i = next_idx  # Move to the next zero element
        end
    end
    return true
end
